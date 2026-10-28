"""Folders and files as the page shows them: the path trail, the file list, reading order,
and when a page needs redrawing."""
import html
import os
import re
import urllib.parse

ICON_DIR = ('<svg class="icon dir" viewBox="0 0 16 16" width="16" height="16"><path d="M1.75 1A1.75 1.75 0 0 0 0 2.75v10.5C0 '
            '14.216.784 15 1.75 15h12.5A1.75 1.75 0 0 0 16 13.25v-8.5A1.75 1.75 0 0 0 14.25 3H7.5a.25.25 0 0 1-.2-.1l-.9-1.2C6.07 '
            '1.26 5.55 1 5 1H1.75Z"/></svg>')
ICON_FILE = ('<svg class="icon" viewBox="0 0 16 16" width="16" height="16"><path d="M2 1.75C2 .784 2.784 0 3.75 0h6.586c.464 0 '
             '.909.184 1.237.513l2.914 2.914c.329.328.513.773.513 1.237v9.586A1.75 1.75 0 0 1 13.25 16h-9.5A1.75 1.75 0 0 1 2 '
             '14.25Zm1.75-.25a.25.25 0 0 0-.25.25v12.5c0 .138.112.25.25.25h9.5a.25.25 0 0 0 .25-.25V6h-2.75A1.75 1.75 0 0 1 9 '
             '4.25V1.5Zm6.75.062V4.25c0 .138.112.25.25.25h2.688l-.011-.013-2.914-2.914-.013-.011Z"/></svg>')


def breadcrumbs(root, url_path):
    """GitHub-style path trail: each parent folder links to its folder view. Each part carries
    its path, so a scoped page can drop the parts above its scope."""
    parts = [p for p in url_path.strip("/").split("/") if p]
    trail = [(os.path.basename(root), "/")]
    for i, part in enumerate(parts):
        href = "/" + "/".join(parts[:i + 1])
        is_last = i == len(parts) - 1
        trail.append((part, href if is_last and not url_path.endswith("/") else href + "/"))
    items = [f'<a href="{html.escape(urllib.parse.quote(href))}" data-path="{html.escape(href)}">{html.escape(name)}</a>'
             for name, href in trail[:-1]]
    items.append(f'<span class="here" data-path="{html.escape(trail[-1][1])}">{html.escape(trail[-1][0])}</span>')
    return '<span class="sep">/</span>'.join(items)


def reading_order(folder):
    """Files the folder's README links to, in the order it lists them. A plan folder's README
    is its read-order index, so its files list brief first, then design, then plan."""
    try:
        with open(os.path.join(folder, "README.md"), encoding="utf-8") as f:
            text = f.read()
    except OSError:
        return []
    order = []
    for target in re.findall(r"\]\(\s*<?(?:\./)?([^)#?\s>/]+)", text):
        name = urllib.parse.unquote(target)
        if name not in order and os.path.isfile(os.path.join(folder, name)):
            order.append(name)
    return order


# Approval shows as a badge on a doc's icon: an empty ring while it's wanted (orange once a
# approved doc has changed), a green tick once it's approved.
APPROVAL_TITLE = {"needed": "Needs your approval", "approved": "Approved by you", "changed": "Changed since you approved it"}
BADGE_TICK = ('<svg viewBox="0 0 16 16" width="8" height="8"><path fill="currentColor" d="M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 '
              '7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.751.751 0 0 1 .018-1.042.751.751 0 0 1 1.042-.018L6 10.94l6.72-6.72a.75.75 0 0 1 '
              '1.06 0Z"/></svg>')


def folder_listing(folder, url_path, current, counts, home="/", changed=(), approvals=None):
    """The file list: folders first, as on GitHub; then the README, as it's the folder's page;
    then files in the README's reading order; then the rest by name. No way up from the top
    of the scope. At the end of a file's row: a dot if it's `changed` since the reader last
    sent comments, and its open comments. A doc's approval state, from `approvals`
    ({name: state}), badges its icon."""
    approvals = approvals or {}
    entries = [e for e in os.scandir(folder) if not e.name.startswith(".")]
    order = reading_order(folder)
    entries.sort(key=lambda e: (not e.is_dir(), e.name != "README.md", e.name not in order,
                                order.index(e.name) if e.name in order else 0, e.name.lower()))
    rows = []
    if url_path not in ("/", home):
        rows.append(f'<a href="{urllib.parse.quote(url_path)}..">{ICON_DIR}..</a>')
    for e in entries:
        href = urllib.parse.quote(url_path + e.name) + ("/" if e.is_dir() else "")
        state = approvals.get(e.name)
        classes = " ".join(filter(None, ["current" if e.name == current else "", f"ap-{state}" if state else ""]))
        cls = f' class="{classes}"' if classes else ""
        icon = ICON_DIR if e.is_dir() else ICON_FILE
        if state:
            cls += f' title="{APPROVAL_TITLE[state]}"'
            icon = f'<span class="fileicon">{icon}<span class="badge">{BADGE_TICK if state == "approved" else ""}</span></span>'
        count = counts.get(url_path + e.name)
        marks = ('<span class="changed" title="Changed since you sent comments"></span>' if e.name in changed else "") \
            + (f'<span class="dot" title="Open comments">{count}</span>' if count else "")
        marks = f'<span class="marks">{marks}</span>' if marks else ""
        rows.append(f'<a href="{href}"{cls}>{icon}{html.escape(e.name)}{marks}</a>')
    return f'<div class="box files">{"".join(rows)}</div>'


def change_marker(path):
    """Something that changes whenever the page for `path` needs redrawing: the folder's file
    names, and the shown file's (or a folder's README's) modified time."""
    try:
        folder, doc = (path, os.path.join(path, "README.md")) if os.path.isdir(path) else (os.path.dirname(path), path)
        names = tuple(sorted(e.name for e in os.scandir(folder)))
        return (names, os.stat(doc).st_mtime_ns if os.path.isfile(doc) else None)
    except FileNotFoundError:
        return None  # editors sometimes delete and rewrite on save
