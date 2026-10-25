"""What the reader last saw of each file, so the page can mark what's changed since.

A copy of a file is kept the first time the reader sees it, or sees the folder it's in, and
replaced when they mark the changes as seen. Copies live beside the comments in the git
folder, mirroring the worktree's paths.
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

    def mark(self, url_path, full):
        """The reader has seen the file as it is now."""
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
