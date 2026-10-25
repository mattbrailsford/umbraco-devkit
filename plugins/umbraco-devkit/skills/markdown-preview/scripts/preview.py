#!/usr/bin/env python3
"""Preview Markdown exactly as GitHub renders it, with live reload and review comments.

Usage:
  preview.py <file-or-folder> [--scope [DIR]] [--no-comments] [--root DIR] [--port N] [--no-open]
  preview.py wait                       block until the reviewer sends comments, then print them
  preview.py comments [--file PATH... | --folder DIR]
                                        list comments waiting on Claude, or every open one on
                                        PATH, or anywhere under DIR (a plan folder, say)
  preview.py reply ID TEXT [--done | --defer STEP] [--move TEXT]
  preview.py approval [--request FILE... [--step NAME]]
                                        ask the reader to approve these docs, or list where
                                        the approvals asked for stand

Renders through GitHub's Markdown API (with the `gh` CLI's sign-in), serves the page on
127.0.0.1 and refreshes it in place whenever the file changes on disk. A folder opens
GitHub-style: its file list beside its README. Readers can leave review comments on any
line, then send them to Claude in one batch, and approve the docs a step asks them to.

One server runs per git worktree; asking again reuses it, and an open preview tab is sent to
the new page rather than opening another. The server stops once its worktree is removed.
Comments live in the worktree's git folder, so they're never committed and any step can read
them without the server running.

The parts: server.py (the web server), comments.py (the comment store), approvals.py (docs
the reader is asked to approve), store.py (the locked file both use), seen.py (what the
reader last saw, for marking changes), folders.py (file lists, reading order), rendering.py
(GitHub's renderer), worktree.py (finding things), and page/ (the page itself).
"""
import argparse
import atexit
import json
import os
import signal
import sys
import threading
import time
import urllib.parse
import urllib.request
import webbrowser

from comments import Comments, describe
from approvals import Approvals
from rendering import Renderer, fetch_css, github_user, repo_context
from seen import Seen
from server import PreviewServer
from worktree import STATE_DIR, git_root, inside, pid_alive, state_paths


# ---------- Claude's comment commands ----------

def comments_command(argv):
    """`wait` blocks until the reviewer sends a batch, or approves every doc asked for, then
    prints it and exits, so a background run of it wakes Claude. `comments` lists what's
    waiting; `reply` answers one; `approval` asks for approvals or lists them."""
    parser = argparse.ArgumentParser(prog="preview.py wait|comments|reply|approval")
    parser.add_argument("command", choices=["wait", "comments", "reply", "approval"])
    parser.add_argument("id", nargs="?")
    parser.add_argument("text", nargs="?")
    # No --resolve: only the reader resolves. --done hands it back to them to check.
    outcome = parser.add_mutually_exclusive_group()
    outcome.add_argument("--done", action="store_true", help="dealt with; the reader checks and resolves it")
    outcome.add_argument("--defer", metavar="STEP", help="another step owns the file; leave it for STEP")
    parser.add_argument("--move", metavar="TEXT", help="re-pin the comment to TEXT, which replaced what it was on")
    parser.add_argument("--file", action="append", help="comments: open comments on this file instead")
    parser.add_argument("--folder", help="comments: every open comment on files under this folder, unsent ones too")
    parser.add_argument("--request", nargs="+", metavar="FILE", help="approval: ask for approval on these docs, replacing the last ask")
    parser.add_argument("--step", help="approval: the step asking")
    parser.add_argument("--root", help="worktree (default: the one holding the current folder)")
    args = parser.parse_args(argv)
    root = os.path.realpath(args.root or git_root(os.getcwd()) or os.getcwd())
    paths = state_paths(root)
    store = Comments(paths.comments)
    approvals = Approvals(paths.approvals)

    def url_path(p):
        rel = os.path.relpath(os.path.realpath(p), root).replace(os.sep, "/")
        return "/" if rel == "." else "/" + rel

    if args.command == "wait":
        if pid_alive(paths.helper):
            return print("Already waiting for comments on this worktree; nothing more to do.")
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(paths.helper, "w") as f:
            f.write(str(os.getpid()))
        atexit.register(lambda: os.path.exists(paths.helper) and os.remove(paths.helper))
        signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
        while True:
            if any(c["status"] == "sent" for c in store.load()):
                batch = store.claim_sent()
                print(f"The reviewer sent {len(batch)} comment{'s' if len(batch) > 1 else ''}:")
                return print(describe(batch))
            approved = approvals.claim_all_approved(root)
            if approved:
                return print("The reviewer approved " + ", ".join(p.lstrip("/") for p in approved)
                             + ". Everything asked for is approved.")
            time.sleep(1)

    if args.command == "approval":
        if args.request:
            wanted = [url_path(f) for f in args.request]
            missing = [f for f, p in zip(args.request, wanted) if not os.path.isfile(root + p)]
            if missing:
                sys.exit("Not found: " + ", ".join(missing))
            approvals.request(wanted, args.step)
            return print("Asked the reviewer to approve " + ", ".join(p.lstrip("/") for p in wanted) + ".")
        states = approvals.states(root)
        if not states:
            return print("No approval asked for.")
        note = {"needed": "waiting for the reviewer's approval", "approved": "approved",
                "changed": "approved, but changed since: needs approving again"}
        return print("\n".join(f"{p.lstrip('/')}: {note[s]}" + (f" ({at})" if s == "approved" else "") for p, s, at in states))

    if args.command == "comments":
        if args.folder:
            # The check before a step moves on: anything unresolved, unsent comments included.
            items = store.unresolved(under=url_path(args.folder).rstrip("/") + "/")  # "/" for the whole worktree
            empty = "No open comments."
        elif args.file:
            # A step's own files: everything open, whoever it's waiting on. Drafts aren't sent yet.
            wanted = {url_path(f) for f in args.file}
            items = [c for c in store.unresolved() if c["path"] in wanted and c["status"] != "draft"]
            empty = "No open comments."
        else:
            items = [c for c in store.load() if c["status"] in ("sent", "working")]
            empty = "No comments waiting."
        return print(describe(items) if items else empty)

    if not (args.id and args.text):
        sys.exit("Usage: preview.py reply <id> <text> [--done | --defer STEP] [--move TEXT]")
    store.claude_reply(args.id, args.text, done=args.done, defer=args.defer, move=args.move)
    outcome = " and marked it done" if args.done else f" and left it for {args.defer}" if args.defer else ""
    print(f"Replied to {args.id}{outcome}" + (" (moved to its new text)" if args.move else ""))


# ---------- opening the preview ----------

def running_port(server_file, root):
    """The port of a live server already previewing this worktree, or None."""
    try:
        with open(server_file) as f:
            state = json.load(f)
        os.kill(state["pid"], 0)
        with urllib.request.urlopen(f"http://127.0.0.1:{state['port']}/__ping", timeout=1) as res:
            return state["port"] if res.read().decode() == root else None
    except (OSError, ValueError, KeyError):
        return None


def stop_when_gone(server, root):
    """A removed worktree has nothing left to preview, so shut down with it."""
    while os.path.isdir(root):
        time.sleep(2)
    server.shutdown()


def open_command(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("path", help="Markdown file or folder to open")
    parser.add_argument("--root", help="folder to serve (default: the git worktree, else the file's folder)")
    parser.add_argument("--port", type=int, default=0, help="port to use (default: any free port)")
    parser.add_argument("--no-open", action="store_true", help="don't open the browser")
    parser.add_argument("--scope", nargs="?", const="", metavar="DIR",
                        help="keep navigation and comments inside DIR (default: the opened folder, or the file's folder)")
    parser.add_argument("--no-comments", action="store_true", help="open read-only, with no review comments")
    args = parser.parse_args(argv)

    target = os.path.realpath(args.path)
    if not os.path.exists(target):
        sys.exit(f"Not found: {args.path}")
    start_dir = target if os.path.isdir(target) else os.path.dirname(target)
    root = os.path.realpath(args.root or git_root(start_dir) or start_dir)
    if not inside(target, root):
        sys.exit(f"{args.path} is not inside {root}")

    rel = os.path.relpath(target, root)
    url_path = "" if rel == "." else urllib.parse.quote(rel) + ("/" if os.path.isdir(target) else "")
    params = {}
    if args.scope is not None:
        scope = os.path.realpath(args.scope) if args.scope else start_dir
        if not inside(scope, root):
            sys.exit(f"{args.scope} is not inside {root}")
        home = "/" + os.path.relpath(scope, root).replace(os.sep, "/") + "/"
        params["home"] = "/" if home == "/./" else home
    if args.no_comments:
        params["comments"] = "off"
    if params:
        url_path += "?" + urllib.parse.urlencode(params)

    # One server per worktree: if it's running, send the open tab there (or open one).
    paths = state_paths(root)
    port = running_port(paths.server, root)
    if port:
        url = f"http://127.0.0.1:{port}/{url_path}"
        if not args.no_open:
            req = urllib.request.Request(f"http://127.0.0.1:{port}/__open", json.dumps({"path": url_path}).encode(), method="POST")
            with urllib.request.urlopen(req, timeout=2) as res:
                reused = res.read().decode() == "reused"
            if not reused:
                webbrowser.open(url)
            print(f"Preview already running for {root}; {'showing it in the open tab' if reused else 'opened'} {url}", flush=True)
        return

    server = PreviewServer(args.port, root=root, css=fetch_css(), renderer=Renderer(repo_context(start_dir)),
                           comments=Comments(paths.comments), seen=Seen(paths.seen), approvals=Approvals(paths.approvals),
                           user=github_user(),
                           helper_file=paths.helper)
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(paths.server, "w") as f:
        json.dump({"root": root, "port": server.port, "pid": os.getpid()}, f)
    atexit.register(lambda: os.path.exists(paths.server) and os.remove(paths.server))
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))  # so atexit still runs when killed
    threading.Thread(target=stop_when_gone, args=(server, root), daemon=True).start()

    url = f"http://127.0.0.1:{server.port}/{url_path}"
    print(f"Previewing {url}", flush=True)

    # Tabs left open from before a restart reconnect within a second; give them the chance
    # before opening another.
    def show():
        time.sleep(1.5)
        if not server.tabs.open(url_path):
            webbrowser.open(url)
    if not args.no_open:
        threading.Thread(target=show, daemon=True).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


def main():
    if len(sys.argv) > 1 and sys.argv[1] in ("wait", "comments", "reply", "approval"):
        return comments_command(sys.argv[1:])
    open_command(sys.argv[1:])


if __name__ == "__main__":
    main()
