"""Turning Markdown into HTML with GitHub's own renderer, so the preview matches github.com."""
import hashlib
import http.client
import json
import subprocess
import threading
import urllib.request

CSS_URL = "https://cdn.jsdelivr.net/npm/github-markdown-css@5.6.1/github-markdown.css"


def fetch_css():
    with urllib.request.urlopen(CSS_URL) as res:
        return res.read().decode()


def repo_context(directory):
    """The repo's owner/name, so `#123` links point at its issues."""
    result = subprocess.run(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
                            cwd=directory, capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


def github_user():
    """The signed-in GitHub login, so comments show the reviewer's own name and avatar."""
    result = subprocess.run(["gh", "api", "user", "-q", ".login"], capture_output=True, text=True)
    return {"login": result.stdout.strip()} if result.returncode == 0 else {}


class Renderer:
    """Renders Markdown via GitHub's API, caching by content.

    Calls GitHub directly over one kept-open connection: spawning `gh` and a fresh TLS
    handshake per render cost about 150ms of each 400ms. The token is read once from
    `gh auth token` and only ever held in memory; without one it falls back to `gh api`.
    """

    SPLIT = "@@umbraco-devkit-split@@"

    def __init__(self, context=None):
        self.context = context
        self.cache = {}
        self.lock = threading.Lock()
        token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True)
        self.token = token.stdout.strip() if token.returncode == 0 else None
        self.conn = None

    def render(self, text):
        key = hashlib.sha256(text.encode()).hexdigest()
        with self.lock:
            if key in self.cache:
                return self.cache[key]
            body = {"text": text, "mode": "gfm"}
            if self.context:
                body["context"] = self.context
            out = self._post(body) if self.token else self._post_with_gh(body)
            if len(self.cache) > 500:
                self.cache.clear()
            self.cache[key] = out
            return out

    def render_many(self, texts):
        """Draw several short texts (comments) in one call, split back apart after."""
        joined = self.render(f"\n\n{self.SPLIT}\n\n".join(texts))
        parts = joined.split(f"<p>{self.SPLIT}</p>")
        if len(parts) != len(texts):  # a text that swallowed the marker: draw them one by one
            parts = [self.render(t) for t in texts]
        return [p.strip() for p in parts]

    def _post(self, body):
        headers = {"Authorization": f"Bearer {self.token}", "Accept": "application/vnd.github+json",
                   "Content-Type": "application/json", "User-Agent": "umbraco-devkit-markdown-preview"}
        for attempt in (1, 2):  # a kept-open connection may have been closed by GitHub
            try:
                if self.conn is None:
                    self.conn = http.client.HTTPSConnection("api.github.com", timeout=20)
                self.conn.request("POST", "/markdown", json.dumps(body), headers)
                res = self.conn.getresponse()
                data = res.read().decode()
            except (OSError, http.client.HTTPException):
                self.conn = None
                if attempt == 2:
                    raise RuntimeError("Can't reach GitHub")
                continue
            if res.status != 200:
                raise RuntimeError(f"GitHub said {res.status}: {data[:200]}")
            return data

    @staticmethod
    def _post_with_gh(body):
        result = subprocess.run(["gh", "api", "-X", "POST", "/markdown", "--input", "-"],
                                input=json.dumps(body), capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "GitHub render failed")
        return result.stdout
