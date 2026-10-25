"""What each doc said when the reader last sent comments, so the page can mark what's
changed since: what Claude did with them.

A copy of a doc is kept the first time the reader sees it, or sees the folder it's in, and
every copy is brought up to date when they send comments. Copies live beside the comments in
the git folder, mirroring the worktree's paths.
"""
import os
import shutil


class Seen:
    def __init__(self, folder):
        self.folder = folder

    def _copy(self, url_path):
        return os.path.join(self.folder, url_path.lstrip("/"))

    def ensure(self, url_path, full):
        """Keep a copy of the file as it is now, unless one is already kept."""
        if not os.path.exists(self._copy(url_path)):
            self.mark(url_path, full)

    def version(self):
        """Changes whenever the copies are all brought up to date, so open pages redraw."""
        try:
            return os.stat(os.path.join(self.folder, ".sent")).st_mtime_ns
        except FileNotFoundError:
            return None

    def mark_all(self, root):
        """The reader has sent comments: from here, changes are Claude's answer to them."""
        for folder, _, files in os.walk(self.folder):
            for name in files:
                if not name.endswith(".md"):
                    continue
                url_path = "/" + os.path.relpath(os.path.join(folder, name), self.folder).replace(os.sep, "/")
                full = os.path.join(root, url_path.lstrip("/"))
                if os.path.isfile(full):
                    self.mark(url_path, full)
        os.makedirs(self.folder, exist_ok=True)
        with open(os.path.join(self.folder, ".sent"), "w") as f:
            f.write("")

    def mark(self, url_path, full):
        """Keep the file as it is now."""
        copy = self._copy(url_path)
        os.makedirs(os.path.dirname(copy), exist_ok=True)
        tmp = f"{copy}.{os.getpid()}.tmp"
        shutil.copyfile(full, tmp)
        os.replace(tmp, copy)

    def before(self, url_path, full):
        """The text the reader last saw, or None if the file hasn't changed since."""
        try:
            with open(self._copy(url_path), encoding="utf-8") as f:
                old = f.read()
            with open(full, encoding="utf-8") as f:
                return None if f.read() == old else old
        except FileNotFoundError:
            return None
