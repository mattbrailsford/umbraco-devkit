"""The preview's web server: the page, the doc drawn by GitHub, and the comment API.

It listens on 127.0.0.1 only, serves files from one worktree and refuses anything outside
it. Requests starting `/__` are the page's own; anything else is a file or folder.
"""
import html
import json
import mimetypes
import os
import re
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from folders import breadcrumbs, change_marker, doc_position, folder_listing
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

    def __init__(self, port, *, root, css, renderer, comments, user, helper_file):
        self.root = root
        self.css = css
        self.renderer = renderer
        self.comments = comments
        self.user = user
        self.helper_file = helper_file
        self.tabs = Tabs()
        with open(os.path.join(PAGE_DIR, "index.html"), encoding="utf-8") as f:
            self.template = f.read()
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

    def resolve(self, url_path):
        """Map a URL path to a file or folder in the worktree, or None (missing, or outside it)."""
        full = os.path.realpath(os.path.join(self.server.root, urllib.parse.unquote(url_path).lstrip("/")))
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
        return self.worktree_file(url.path)

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

    def page(self, url_path, docname):
        """The preview page, filled in for one file or folder."""
        unquoted = urllib.parse.unquote(url_path)
        boot = json.dumps({"path": url_path, "user": self.server.user}).replace("</", "<\\/")
        fill = {"title": html.escape(unquoted), "github_css": self.server.css, "crumbs": breadcrumbs(self.server.root, unquoted),
                "docname": html.escape(docname), "boot": boot}
        self.send(200, re.sub(r"\{\{(\w+)\}\}", lambda m: fill[m.group(1)], self.server.template))

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

    def worktree_file(self, url_path):
        """A folder or Markdown file gets the preview page; anything else (an image, say) is sent as is."""
        found = self.resolve(url_path)
        if not found:
            return self.send(404, "Not found", "text/plain")
        if os.path.isdir(found):
            if not url_path.endswith("/"):
                self.send_response(301)
                self.send_header("Location", url_path + "/")
                self.end_headers()
                return
            return self.page(url_path, "README.md")
        if found.endswith(".md"):
            return self.page(url_path, os.path.basename(found))
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
        if found:
            self.send(200, folder_listing(found, self.query["path"], self.query.get("current", ""),
                                          self.server.comments.open_counts(), self.query.get("home", "/")))

    def get_changes(self):
        """What the page polls: markers that change when the doc or the comments do, and a page
        to go to if another request is reusing this tab."""
        found = self.target()
        if not found:
            return
        tabs = self.server.tabs
        marks = {"doc": repr(change_marker(found)), "comments": repr(self.server.comments.mtime())}
        tabs.seen = time.time()
        if tabs.go_to:
            marks["navigate"], tabs.go_to = tabs.go_to, None
        self.send_json(marks)

    def get_comments(self):
        store = self.server.comments
        if "drafts" in self.query:
            return self.send_json(store.drafts())
        if "open" in self.query:
            items, sources = store.unresolved(), {}
            for c in items:
                c["place"] = doc_position(self.server.root, c, sources)
            return self.send_json(items)
        self.send_json(store.on_file(self.query.get("path", "")))

    def post_markdown(self):
        try:
            self.send_json({"html": self.server.renderer.render_many(self.data["texts"])})
        except (KeyError, ValueError):
            raise
        except Exception as e:
            self.send(502, str(e), "text/plain")

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
}
POST_ROUTES = {
    "/__md": Handler.post_markdown,
    "/__open": Handler.post_open,
    "/__comments": Handler.post_comment,
    "/__comments/send": Handler.post_send,
    "/__comments/resolve": Handler.post_resolve,
    "/__comments/edit": Handler.post_edit,
    "/__comments/reply": Handler.post_reply,
    "/__comments/delete": Handler.post_delete,
}
