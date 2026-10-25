"""The preview's web server: the page, the doc drawn by GitHub, and the comment API.

It listens on 127.0.0.1 only, serves files from one worktree and refuses anything outside
it. Requests starting `/__` are the page's own; anything else is a file or folder.

Paths are decoded once, where they come in (the request's own path, or a query or body
value), and stay plain from there: "/docs/my plan/BRIEF.md", never "my%20plan". Comments,
approvals and Claude's commands all key files that way.
"""
import html
import json
import mimetypes
import os
import re
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from folders import breadcrumbs, change_marker, folder_listing
from worktree import inside, pid_alive

PAGE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "page")


class Tabs:
    """Whether a preview tab is open (they check in every 0.4s), and where to send it next, so
    asking to open another file reuses the tab rather than opening a new one."""

    def __init__(self):
        self.seen = 0.0
        self.go_to = None

    def open(self, url_path):
        """Point the open tab at url_path; False if no tab has checked in lately."""
        if time.time() - self.seen > 2:
            return False
        self.go_to = "/" + url_path
        return True


class PreviewServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, port, *, root, css, renderer, comments, seen, approvals, user, helper_file):
        self.root = root
        self.css = css
        self.renderer = renderer
        self.comments = comments
        self.seen = seen
        self.approvals = approvals
        self.user = user
        self.helper_file = helper_file
        self.tabs = Tabs()
        super().__init__(("127.0.0.1", port), Handler)

    @property
    def port(self):
        return self.server_address[1]


class BadRequest(Exception):
    pass


class Handler(BaseHTTPRequestHandler):
    server: PreviewServer

    def log_message(self, *args):
        pass

    # ---------- plumbing ----------

    def resolve(self, path):
        """Map a plain path to a file or folder in the worktree, or None (missing, or outside it)."""
        full = os.path.realpath(os.path.join(self.server.root, path.lstrip("/")))
        return full if inside(full, self.server.root) and os.path.exists(full) else None

    def send(self, status, body, content_type="text/html; charset=utf-8"):
        data = body.encode() if isinstance(body, str) else body
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def send_json(self, value):
        self.send(200, json.dumps(value), "application/json")

    def do_GET(self):
        url = urllib.parse.urlparse(self.path)
        self.query = {k: v[0] for k, v in urllib.parse.parse_qs(url.query).items()}
        route = GET_ROUTES.get(url.path)
        if route:
            return route(self)
        if url.path.startswith("/__page/"):
            return self.page_file(url.path[len("/__page/"):])
        return self.worktree_file(urllib.parse.unquote(url.path))

    def do_POST(self):
        route = POST_ROUTES.get(urllib.parse.urlparse(self.path).path)
        if not route:
            return self.send(404, "Not found", "text/plain")
        try:
            self.data = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
            route(self)
        except (KeyError, ValueError, BadRequest) as e:
            return self.send(400, f"Bad request: {e}", "text/plain")

    def target(self):
        """The file or folder named by ?path=, or a 404 sent and None."""
        found = self.resolve(self.query.get("path", ""))
        if not found:
            self.send(404, "Not found", "text/plain")
        return found

    # ---------- pages and files ----------

    def page(self, path, docname):
        """The preview page, filled in for one file or folder."""
        boot = json.dumps({"path": path, "user": self.server.user}).replace("</", "<\\/")
        fill = {"title": html.escape(path), "github_css": self.server.css, "crumbs": breadcrumbs(self.server.root, path),
                "docname": html.escape(docname), "boot": boot}
        # Read each time, as the page's scripts and styles are, so a running server never mixes
        # an old page with new ones.
        with open(os.path.join(PAGE_DIR, "index.html"), encoding="utf-8") as f:
            template = f.read()
        self.send(200, re.sub(r"\{\{(\w+)\}\}", lambda m: fill[m.group(1)], template))

    def page_file(self, name):
        """The page's own scripts and styles, from page/."""
        if not re.fullmatch(r"[\w-]+\.(js|css)", name):
            return self.send(404, "Not found", "text/plain")
        try:
            with open(os.path.join(PAGE_DIR, name), "rb") as f:
                body = f.read()
        except FileNotFoundError:
            return self.send(404, "Not found", "text/plain")
        self.send(200, body, "text/javascript; charset=utf-8" if name.endswith(".js") else "text/css; charset=utf-8")

    def worktree_file(self, path):
        """A folder or Markdown file gets the preview page; anything else (an image, say) is sent as is."""
        found = self.resolve(path)
        if not found:
            return self.send(404, "Not found", "text/plain")
        if os.path.isdir(found):
            if not path.endswith("/"):
                self.send_response(301)
                self.send_header("Location", urllib.parse.quote(path + "/"))
                self.end_headers()
                return
            return self.page(path, "README.md")
        if found.endswith(".md"):
            return self.page(path, os.path.basename(found))
        with open(found, "rb") as f:
            self.send(200, f.read(), mimetypes.guess_type(found)[0] or "application/octet-stream")

    # ---------- the page's own requests ----------

    def get_ping(self):
        self.send(200, self.server.root, "text/plain")

    def get_listening(self):
        """Whether Claude's helper is waiting for a batch, for the "Sent" note."""
        self.send(200, "1" if pid_alive(self.server.helper_file) else "0", "text/plain")

    def get_render(self):
        found = self.target()
        if not found:
            return
        if not os.path.isfile(found):
            return self.send(404, "Not found", "text/plain")
        try:
            with open(found, encoding="utf-8") as f:
                self.send(200, self.server.renderer.render(f.read()))
        except Exception as e:  # GitHub unreachable, or gh signed out: shown on the page
            self.send(502, str(e), "text/plain")

    def get_list(self):
        found = self.target()
        if not found:
            return
        # Seeing a folder counts as seeing its docs as they are, so a later change to one shows.
        url_path, changed, approvals = self.query["path"], set(), {}
        asked = self.server.approvals.load()
        for e in os.scandir(found):
            if e.is_file() and e.name.endswith(".md"):
                key = url_path + e.name
                self.server.seen.ensure(key, e.path)
                if self.server.seen.before(key, e.path) is not None:
                    changed.add(e.name)
                approvals[e.name] = self.server.approvals.state(key, e.path, asked)[0]
        self.send(200, folder_listing(found, url_path, self.query.get("current", ""),
                                      self.server.comments.open_counts(), self.query.get("home", "/"), changed, approvals))

    def get_seen(self):
        """The doc as it was when the reader last sent comments (or first saw it), drawn, if
        it's changed since: {"html": ...}, else {}."""
        found = self.target()
        if not found:
            return
        if not os.path.isfile(found):
            return self.send(404, "Not found", "text/plain")
        url_path = self.query["path"]
        self.server.seen.ensure(url_path, found)
        old = self.server.seen.before(url_path, found)
        try:
            self.send_json({} if old is None else {"html": self.server.renderer.render(old)})
        except Exception as e:  # GitHub unreachable: the page just shows no changes
            self.send(502, str(e), "text/plain")

    def get_changes(self):
        """What the page polls: markers that change when the doc or the comments do, and a page
        to go to if another request is reusing this tab."""
        found = self.target()
        if not found:
            return
        tabs = self.server.tabs
        marks = {"doc": repr((change_marker(found), self.server.seen.version())),
                 "comments": repr((self.server.comments.mtime(), self.server.approvals.mtime()))}
        tabs.seen = time.time()
        if tabs.go_to:
            marks["navigate"], tabs.go_to = tabs.go_to, None
        self.send_json(marks)

    def get_comments(self):
        store = self.server.comments
        if "drafts" in self.query:
            return self.send_json(store.drafts())
        self.send_json(store.on_file(self.query.get("path", "")))

    def get_approval(self):
        """Whether this doc is asked to be approved, and where that stands."""
        found = self.target()
        if not found:
            return
        path = self.query["path"]
        state, at = self.server.approvals.state(path, found) if os.path.isfile(found) else (None, None)
        open_comments = len([c for c in self.server.comments.unresolved() if c["path"] == path])
        self.send_json({"state": state, "at": at, "open": open_comments})

    def post_markdown(self):
        try:
            self.send_json({"html": self.server.renderer.render_many(self.data["texts"])})
        except (KeyError, ValueError):
            raise
        except Exception as e:
            self.send(502, str(e), "text/plain")

    def post_approve(self):
        """The reader approves a doc: only once its comments are all resolved."""
        path = self.data["path"]
        found = self.resolve(path)
        if not found or not os.path.isfile(found):
            raise BadRequest("no such file")
        if any(c["path"] == path for c in self.server.comments.unresolved()):
            raise BadRequest("resolve the open comments first")
        self.server.approvals.approve(path, found)
        self.ok()

    def post_open(self):
        self.send(200, "reused" if self.server.tabs.open(self.data["path"]) else "none", "text/plain")

    def post_comment(self):
        d = self.data
        if not self.resolve(d["path"]):
            raise BadRequest("no such file")
        self.server.comments.add(d["path"], d["quote"], d["body"], d.get("prefix", ""), d.get("suffix", ""), d.get("section", ""))
        self.ok()

    def ok(self):
        self.send(200, "ok", "text/plain")

    def post_send(self):
        self.server.seen.mark_all(self.server.root)  # before Claude can start on them
        self.server.comments.send_drafts()
        self.ok()

    def post_resolve(self):
        self.server.comments.resolve(self.data["id"])
        self.ok()

    def post_edit(self):
        self.server.comments.edit(self.data["id"], self.data["body"])
        self.ok()

    def post_reply(self):
        self.server.comments.reader_reply(self.data["id"], self.data["body"])
        self.ok()

    def post_delete(self):
        self.server.comments.delete(self.data["id"])
        self.ok()


GET_ROUTES = {
    "/__ping": Handler.get_ping,
    "/__listening": Handler.get_listening,
    "/__render": Handler.get_render,
    "/__list": Handler.get_list,
    "/__changes": Handler.get_changes,
    "/__comments": Handler.get_comments,
    "/__seen": Handler.get_seen,
    "/__approve": Handler.get_approval,
}
POST_ROUTES = {
    "/__md": Handler.post_markdown,
    "/__open": Handler.post_open,
    "/__approve": Handler.post_approve,
    "/__comments": Handler.post_comment,
    "/__comments/send": Handler.post_send,
    "/__comments/resolve": Handler.post_resolve,
    "/__comments/edit": Handler.post_edit,
    "/__comments/reply": Handler.post_reply,
    "/__comments/delete": Handler.post_delete,
}
