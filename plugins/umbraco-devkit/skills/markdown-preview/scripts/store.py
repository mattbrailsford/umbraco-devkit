"""A JSON file that the page server and Claude's commands both change, from separate
processes: every change holds a file lock for its whole read-change-write."""
import fcntl
import json
import os
import threading
import time


def now():
    return time.strftime("%Y-%m-%dT%H:%M:%S")


class JsonStore:
    empty = list  # what a missing or unreadable file holds

    def __init__(self, path):
        self.path = path
        self.lock = threading.Lock()  # flock is per process; this covers the server's threads

    def mtime(self):
        return os.stat(self.path).st_mtime_ns if os.path.exists(self.path) else None

    def load(self):
        try:
            with open(self.path) as f:
                return json.load(f)
        except (FileNotFoundError, ValueError):
            return self.empty()

    def _save(self, data):
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        tmp = f"{self.path}.{os.getpid()}.tmp"
        with open(tmp, "w") as f:
            json.dump(data, f, indent=1)
        os.replace(tmp, self.path)  # readers never see a half-written file

    def change(self, fn):
        """Run fn(data) on the stored data and save it, with no other change in between. Saved
        only if fn changed something: open pages redraw whenever the file does, and a redraw
        closes whatever the reader has open."""
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        with self.lock, open(self.path + ".lock", "a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            data = self.load()
            before = json.dumps(data, sort_keys=True)
            result = fn(data)
            if json.dumps(data, sort_keys=True) != before:
                self._save(data)
            return result
