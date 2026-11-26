"""Finding the worktree a file is in, and where its preview keeps things."""
import hashlib
import os
import shutil
import tempfile
from collections import namedtuple

import compat

# Things that only matter while running (the server's port, the waiting helper) live here.
STATE_DIR = os.path.join(tempfile.gettempdir(), "umbraco-devkit-preview")

StatePaths = namedtuple("StatePaths", "server comments helper seen approvals")


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


def session_id():
    """The Claude Code session running this, so two sessions on one worktree each get their
    own tab, helper and comments. Empty outside Claude Code: one shared session."""
    return os.environ.get("CLAUDE_PID") or os.environ.get("CLAUDE_CODE_SESSION_ID") or ""


def data_dir(root):
    """The preview's own files in a worktree: `.umbraco-devkit/markdown-preview/`. The
    `.umbraco-devkit` folder ignores itself, so nothing in it is ever committed and the
    project's own `.gitignore` is never touched. Files kept in the worktree's git folder by
    earlier versions move here the first time."""
    devkit = os.path.join(root, ".umbraco-devkit")
    folder = os.path.join(devkit, "markdown-preview")
    ignore = os.path.join(devkit, ".gitignore")
    if not os.path.exists(ignore):
        os.makedirs(devkit, exist_ok=True)
        with open(ignore, "w") as f:
            f.write("*\n")
    git_dir = find_git(root)[1]
    old = os.path.join(git_dir, "markdown-preview") if git_dir else None
    if old and os.path.isdir(old) and not os.path.exists(folder):
        shutil.move(old, folder)
    return folder


def state_paths(root, session=""):
    """Where a worktree's server details, comments, approvals, waiting helper and copies of
    what the reader last saw are kept. Each session has its own helper.

    Comments, approvals and copies go in the worktree's `.umbraco-devkit/markdown-preview/`:
    never committed, kept across restarts, and removed with the worktree. Outside a repo they
    fall back to the temp folder.
    """
    key = hashlib.sha1(root.encode()).hexdigest()[:16]
    helper = key + ("-" + hashlib.sha1(session.encode()).hexdigest()[:8] if session else "") + "-waiter.pid"
    data = data_dir(root) if find_git(root)[0] else None
    comments = (os.path.join(data, "comments.json") if data
                else os.path.join(STATE_DIR, key + "-comments.json"))
    seen = (os.path.join(data, "seen") if data
            else os.path.join(STATE_DIR, key + "-seen"))
    approvals = (os.path.join(data, "approvals.json") if data
                 else os.path.join(STATE_DIR, key + "-approvals.json"))
    return StatePaths(os.path.join(STATE_DIR, key + ".json"), comments, os.path.join(STATE_DIR, helper),
                      seen, approvals)


def pid_alive(pid_file):
    """Whether the process whose id is in `pid_file` is still running."""
    try:
        with open(pid_file) as f:
            return compat.pid_running(f.read())
    except (OSError, ValueError):
        return False


def inside(path, root):
    return path == root or path.startswith(root + os.sep)
