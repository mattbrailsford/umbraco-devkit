"""Finding the worktree a file is in, and where its preview keeps things."""
import hashlib
import os
import tempfile
from collections import namedtuple

# Things that only matter while running (the server's port, the waiting helper) live here.
STATE_DIR = os.path.join(tempfile.gettempdir(), "umbraco-devkit-preview")

StatePaths = namedtuple("StatePaths", "server comments helper seen")


def find_git(start):
    """The worktree holding `start` and its git folder, found by walking up for `.git` rather
    than running git, so it also works where git can't run. (None, None) outside a repo."""
    d = os.path.realpath(start)
    while True:
        dot = os.path.join(d, ".git")
        if os.path.isdir(dot):
            return d, dot
        if os.path.isfile(dot):  # a linked worktree: `.git` is a file naming its git folder
            with open(dot) as f:
                line = f.read().strip()
            if line.startswith("gitdir:"):
                return d, os.path.realpath(os.path.join(d, line[len("gitdir:"):].strip()))
        parent = os.path.dirname(d)
        if parent == d:
            return None, None
        d = parent


def git_root(directory):
    return find_git(directory)[0]


def state_paths(root):
    """Where a worktree's server details, comments, waiting helper and copies of what the
    reader last saw are kept.

    Comments and copies go in the worktree's git folder: never committed, kept across restarts, and
    removed with the worktree. Outside a repo they fall back to the temp folder.
    """
    key = hashlib.sha1(root.encode()).hexdigest()[:16]
    git_dir = find_git(root)[1]
    comments = (os.path.join(git_dir, "markdown-preview", "comments.json") if git_dir
                else os.path.join(STATE_DIR, key + "-comments.json"))
    seen = (os.path.join(git_dir, "markdown-preview", "seen") if git_dir
            else os.path.join(STATE_DIR, key + "-seen"))
    return StatePaths(os.path.join(STATE_DIR, key + ".json"), comments, os.path.join(STATE_DIR, key + "-waiter.pid"), seen)


def pid_alive(pid_file):
    """Whether the process whose id is in `pid_file` is still running."""
    try:
        with open(pid_file) as f:
            os.kill(int(f.read()), 0)
        return True
    except (OSError, ValueError):
        return False


def inside(path, root):
    return path == root or path.startswith(root + os.sep)
