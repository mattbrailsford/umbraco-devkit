#!/usr/bin/env python3
"""Preview Markdown exactly as GitHub renders it, with live reload.

Usage: preview.py <file-or-folder> [--root DIR] [--port N] [--no-open]

Renders through GitHub's Markdown API (via the `gh` CLI, so it reuses your
existing sign-in), serves the page on 127.0.0.1 and refreshes it in place
whenever the file changes on disk. A folder opens GitHub-style: its file
list beside its README.

One server runs per git worktree. If one is already running for the
worktree, this opens the page on it and exits. The server stops by itself
once its worktree folder is removed.
"""
import argparse
import atexit
import hashlib
import html
import json
import mimetypes
import os
import signal
import subprocess
import sys
import tempfile
import threading
import time
import urllib.parse
import urllib.request
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CSS_URL = "https://cdn.jsdelivr.net/npm/github-markdown-css@5.6.1/github-markdown.css"
POLL_SECONDS = 0.3
STATE_DIR = os.path.join(tempfile.gettempdir(), "umbraco-devkit-preview")

ICON_DIR = ('<svg class="icon dir" viewBox="0 0 16 16" width="16" height="16"><path d="M1.75 1A1.75 1.75 0 0 0 0 2.75v10.5C0 '
            '14.216.784 15 1.75 15h12.5A1.75 1.75 0 0 0 16 13.25v-8.5A1.75 1.75 0 0 0 14.25 3H7.5a.25.25 0 0 1-.2-.1l-.9-1.2C6.07 '
            '1.26 5.55 1 5 1H1.75Z"/></svg>')
ICON_FILE = ('<svg class="icon" viewBox="0 0 16 16" width="16" height="16"><path d="M2 1.75C2 .784 2.784 0 3.75 0h6.586c.464 0 '
             '.909.184 1.237.513l2.914 2.914c.329.328.513.773.513 1.237v9.586A1.75 1.75 0 0 1 13.25 16h-9.5A1.75 1.75 0 0 1 2 '
             '14.25Zm1.75-.25a.25.25 0 0 0-.25.25v12.5c0 .138.112.25.25.25h9.5a.25.25 0 0 0 .25-.25V6h-2.75A1.75 1.75 0 0 1 9 '
             '4.25V1.5Zm6.75.062V4.25c0 .138.112.25.25.25h2.688l-.011-.013-2.914-2.914-.013-.011Z"/></svg>')

PAGE = """<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__</title>
<style>
__CSS__
:root { --bg: #ffffff; --fg: #1f2328; --muted: #59636e; --border: #d1d9e0; --header: #f6f8fa; --link: #0969da; --hover: #f6f8fa; }
@media (prefers-color-scheme: dark) {
  :root { --bg: #0d1117; --fg: #f0f6fc; --muted: #9198a1; --border: #3d444d; --header: #151b23; --link: #4493f8; --hover: #151b23; }
}
body { margin: 0; background: var(--bg); color: var(--fg); font: 14px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
main { box-sizing: border-box; max-width: 1280px; margin: 0 auto; padding: 24px 16px 48px; }
.layout { display: grid; grid-template-columns: 260px minmax(0, 1fr); gap: 24px; align-items: start; }
aside { position: sticky; top: 16px; max-height: calc(100vh - 32px); overflow-y: auto; }
aside summary { display: none; }
@media (max-width: 900px) {
  .layout { grid-template-columns: minmax(0, 1fr); }
  aside { position: static; max-height: none; }
  aside summary { display: block; cursor: pointer; padding: 8px 0; font-weight: 600; color: var(--link); }
}
.files a.current { background: var(--hover); font-weight: 600; box-shadow: inset 2px 0 0 var(--link); }
.crumbs { font-size: 20px; margin-bottom: 16px; word-break: break-all; }
.crumbs a { color: var(--link); text-decoration: none; }
.crumbs a:hover { text-decoration: underline; }
.crumbs .sep { color: var(--muted); margin: 0 4px; }
.crumbs .here { font-weight: 600; }
.box { border: 1px solid var(--border); border-radius: 6px; margin-bottom: 16px; overflow: hidden; }
.box-header { background: var(--header); border-bottom: 1px solid var(--border); padding: 10px 16px; font-weight: 600; }
.files a { display: flex; gap: 10px; align-items: center; padding: 8px 16px; color: var(--fg); text-decoration: none; border-top: 1px solid var(--border); }
.files a:first-child { border-top: 0; }
.files a:hover { background: var(--hover); color: var(--link); }
.icon { fill: var(--muted); flex: none; }
.icon.dir { fill: #54aeff; }
.markdown-body { box-sizing: border-box; padding: 32px; }
@media (max-width: 767px) { .markdown-body { padding: 16px; } }
.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
#status { position: fixed; top: 8px; right: 8px; padding: 4px 10px; border-radius: 6px; font-size: 12px; display: none; }
#status.error { display: block; background: #d1242f; color: #fff; }
#status.busy { display: block; background: #0969da; color: #fff; }
</style>
</head>
<body>
<div id="status"></div>
<main>
<nav class="crumbs">__CRUMBS__</nav>
<div class="layout">
<aside><details id="filebox"><summary>Files in this folder</summary><div id="files"></div></details></aside>
<div class="box" id="doc" hidden>
  <div class="box-header">__DOCNAME__</div>
  <article id="content" class="markdown-body"></article>
</div>
</div>
</main>
<script src="https://cdn.jsdelivr.net/npm/mermaid@11.3.0/dist/mermaid.min.js"></script>
<script>
window.MathJax = { tex: { inlineMath: [['$', '$']], displayMath: [['$$', '$$']] } };
</script>
<script async src="https://cdn.jsdelivr.net/npm/mathjax@3.2.2/es5/tex-mml-chtml.js"></script>
<script>
const pagePath = __PATH__;
const isFolder = pagePath.endsWith('/');
const folderPath = pagePath.slice(0, pagePath.lastIndexOf('/') + 1);
// The file list sits beside the content on wide screens; on narrow ones it folds away.
document.getElementById('filebox').open = matchMedia('(min-width: 901px)').matches;
const content = document.getElementById('content');
const status = document.getElementById('status');
const dark = matchMedia('(prefers-color-scheme: dark)').matches;
mermaid.initialize({ startOnLoad: false, theme: dark ? 'dark' : 'default' });
let renderCount = 0;

function showStatus(text, kind) {
  status.textContent = text;
  status.className = kind || '';
}

// GitHub finishes several things in the browser; repeat them after each render.
function enhance() {
  const seen = {};
  content.querySelectorAll('h1,h2,h3,h4,h5,h6').forEach(h => {
    let slug = h.textContent.trim().toLowerCase().replace(/[^\\p{L}\\p{N}\\s_-]/gu, '').replace(/\\s/g, '-');
    const n = seen[slug] = (seen[slug] ?? -1) + 1;
    if (n) slug += '-' + n;
    h.id = slug;
  });
  content.querySelectorAll('[id^="user-content-"]').forEach(el => el.id = el.id.slice(13));
  content.querySelectorAll('a[href^="#user-content-"]').forEach(a => a.setAttribute('href', '#' + a.getAttribute('href').slice(14)));

  const run = ++renderCount;
  content.querySelectorAll('div.highlight-source-mermaid > pre').forEach(async (pre, i) => {
    try { pre.innerHTML = (await mermaid.render(`mermaid-${run}-${i}`, pre.textContent)).svg; } catch (e) { console.error(e); }
  });

  if (window.MathJax?.typesetPromise) {
    MathJax.typesetClear([content]);
    MathJax.typesetPromise([content]).catch(console.error);
  }
}

async function fetchText(url) {
  const res = await fetch(url);
  const text = await res.text();
  if (!res.ok) throw new Error(text);
  return text;
}

async function load() {
  showStatus('Rendering…', 'busy');
  try {
    const y = scrollY;
    document.getElementById('files').innerHTML = await fetchText('/__list?path=' + encodeURIComponent(folderPath)
      + '&current=' + encodeURIComponent(isFolder ? 'README.md' : pagePath.slice(folderPath.length)));
    const doc = isFolder ? pagePath + 'README.md' : pagePath;
    const res = await fetch('/__render?path=' + encodeURIComponent(doc));
    const box = document.getElementById('doc');
    if (res.status === 404 && isFolder) {
      box.hidden = true;  // a folder without a README shows just its file list
    } else {
      const text = await res.text();
      if (!res.ok) throw new Error(text);
      content.innerHTML = text;
      box.hidden = false;
      enhance();
    }
    scrollTo(0, y);
    showStatus('');
    if (location.hash && renderCount === 1) document.getElementById(location.hash.slice(1))?.scrollIntoView();
  } catch (e) {
    showStatus(e.message, 'error');
  }
}

const events = new EventSource('/__events?path=' + encodeURIComponent(pagePath));
events.onmessage = load;
events.onerror = () => showStatus('Preview server stopped', 'error');
</script>
</body>
</html>
"""


class Renderer:
    """Renders Markdown via GitHub, caching by content hash."""

    def __init__(self, context):
        self.context = context
        self.cache = {}
        self.lock = threading.Lock()

    def render(self, text):
        key = hashlib.sha256(text.encode()).hexdigest()
        with self.lock:
            if key in self.cache:
                return self.cache[key]
        body = {"text": text, "mode": "gfm"}
        if self.context:
            body["context"] = self.context
        result = subprocess.run(
            ["gh", "api", "-X", "POST", "/markdown", "--input", "-"],
            input=json.dumps(body), capture_output=True, text=True,
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "GitHub render failed")
        with self.lock:
            if len(self.cache) > 50:
                self.cache.clear()
            self.cache[key] = result.stdout
        return result.stdout


def repo_context(directory):
    result = subprocess.run(
        ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
        cwd=directory, capture_output=True, text=True,
    )
    return result.stdout.strip() if result.returncode == 0 else None


def git_root(directory):
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], cwd=directory, capture_output=True, text=True,
    )
    return result.stdout.strip() if result.returncode == 0 else None


def breadcrumbs(root, url_path):
    """GitHub-style path trail: each parent folder links to its folder view."""
    parts = [p for p in url_path.strip("/").split("/") if p]
    trail = [(os.path.basename(root), "/")]
    for i, part in enumerate(parts):
        href = "/" + "/".join(parts[:i + 1])
        is_last = i == len(parts) - 1
        trail.append((part, href if is_last and not url_path.endswith("/") else href + "/"))
    items = [f'<a href="{html.escape(urllib.parse.quote(href))}">{html.escape(name)}</a>' for name, href in trail[:-1]]
    items.append(f'<span class="here">{html.escape(trail[-1][0])}</span>')
    return '<span class="sep">/</span>'.join(items)


def folder_listing(folder, url_path, current):
    entries = [e for e in os.scandir(folder) if not e.name.startswith(".")]
    entries.sort(key=lambda e: (not e.is_dir(), e.name.lower()))
    rows = []
    if url_path != "/":
        rows.append(f'<a href="{urllib.parse.quote(url_path)}..">{ICON_DIR}..</a>')
    for e in entries:
        href = urllib.parse.quote(url_path + e.name) + ("/" if e.is_dir() else "")
        cls = ' class="current"' if e.name == current else ""
        rows.append(f'<a href="{href}"{cls}>{ICON_DIR if e.is_dir() else ICON_FILE}{html.escape(e.name)}</a>')
    return f'<div class="box files">{"".join(rows)}</div>'


def change_marker(path):
    """Something that changes whenever the page for `path` needs a refresh."""
    try:
        folder, doc = (path, os.path.join(path, "README.md")) if os.path.isdir(path) else (os.path.dirname(path), path)
        names = tuple(sorted(e.name for e in os.scandir(folder)))
        return (names, os.stat(doc).st_mtime_ns if os.path.isfile(doc) else None)
    except FileNotFoundError:
        return None  # editors sometimes delete and rewrite on save


def make_handler(root, css, renderer):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def resolve(self, url_path):
            """Map a URL path to a file or folder under root, refusing anything outside it."""
            rel = urllib.parse.unquote(url_path).lstrip("/")
            full = os.path.realpath(os.path.join(root, rel))
            if full != root and not full.startswith(root + os.sep):
                return None
            return full if os.path.exists(full) else None

        def send(self, status, body, content_type="text/html; charset=utf-8"):
            data = body.encode() if isinstance(body, str) else body
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)

        def page(self, url_path, docname):
            body = (PAGE.replace("__CSS__", css)
                        .replace("__TITLE__", html.escape(urllib.parse.unquote(url_path)))
                        .replace("__CRUMBS__", breadcrumbs(root, urllib.parse.unquote(url_path)))
                        .replace("__DOCNAME__", html.escape(docname))
                        .replace("__PATH__", json.dumps(url_path)))
            self.send(200, body)

        def do_GET(self):
            url = urllib.parse.urlparse(self.path)
            query = urllib.parse.parse_qs(url.query)

            if url.path == "/__ping":
                return self.send(200, root, "text/plain")
            if url.path in ("/__render", "/__events", "/__list"):
                target = self.resolve(query.get("path", [""])[0])
                if not target:
                    return self.send(404, "Not found", "text/plain")
                if url.path == "/__render":
                    return self.render(target)
                if url.path == "/__list":
                    current = query.get("current", [""])[0]
                    return self.send(200, folder_listing(target, query["path"][0], current))
                return self.events(target)

            target = self.resolve(url.path)
            if not target:
                return self.send(404, "Not found", "text/plain")
            if os.path.isdir(target):
                if not url.path.endswith("/"):
                    self.send_response(301)
                    self.send_header("Location", url.path + "/")
                    self.end_headers()
                    return
                return self.page(url.path, "README.md")
            if target.endswith(".md"):
                return self.page(url.path, os.path.basename(target))
            with open(target, "rb") as f:
                self.send(200, f.read(), mimetypes.guess_type(target)[0] or "application/octet-stream")

        def render(self, doc):
            if not os.path.isfile(doc):
                return self.send(404, "Not found", "text/plain")
            try:
                with open(doc, encoding="utf-8") as f:
                    self.send(200, renderer.render(f.read()))
            except Exception as e:
                self.send(502, str(e), "text/plain")

        def events(self, target):
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            last = object()
            try:
                while True:
                    marker = change_marker(target)
                    if marker is not None and marker != last:
                        last = marker
                        self.wfile.write(b"data: changed\n\n")
                    else:
                        self.wfile.write(b": ping\n\n")
                    self.wfile.flush()
                    time.sleep(POLL_SECONDS)
            except (BrokenPipeError, ConnectionResetError):
                pass

    return Handler


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("path", help="Markdown file or folder to open")
    parser.add_argument("--root", help="folder to serve (default: the git worktree, else the file's folder)")
    parser.add_argument("--port", type=int, default=0, help="port to use (default: any free port)")
    parser.add_argument("--no-open", action="store_true", help="don't open the browser")
    args = parser.parse_args()

    target = os.path.realpath(args.path)
    if not os.path.exists(target):
        sys.exit(f"Not found: {args.path}")
    start_dir = target if os.path.isdir(target) else os.path.dirname(target)
    root = os.path.realpath(args.root or git_root(start_dir) or start_dir)
    if target != root and not target.startswith(root + os.sep):
        sys.exit(f"{args.path} is not inside {root}")

    rel = os.path.relpath(target, root)
    url_path = "" if rel == "." else urllib.parse.quote(rel) + ("/" if os.path.isdir(target) else "")

    state_file = os.path.join(STATE_DIR, hashlib.sha1(root.encode()).hexdigest()[:16] + ".json")
    port = running_port(state_file, root)
    if port:
        url = f"http://127.0.0.1:{port}/{url_path}"
        print(f"Preview already running for {root}; opened {url}", flush=True)
        if not args.no_open:
            webbrowser.open(url)
        return

    with urllib.request.urlopen(CSS_URL) as res:
        css = res.read().decode()
    renderer = Renderer(repo_context(start_dir))

    server = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(root, css, renderer))
    server.daemon_threads = True
    port = server.server_address[1]
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(state_file, "w") as f:
        json.dump({"root": root, "port": port, "pid": os.getpid()}, f)
    atexit.register(lambda: os.path.exists(state_file) and os.remove(state_file))
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))  # so atexit still runs when killed
    threading.Thread(target=stop_when_gone, args=(server, root), daemon=True).start()

    url = f"http://127.0.0.1:{port}/{url_path}"
    print(f"Previewing {url}", flush=True)
    if not args.no_open:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


def running_port(state_file, root):
    """The port of a live server already previewing this root, or None."""
    try:
        with open(state_file) as f:
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


if __name__ == "__main__":
    main()
