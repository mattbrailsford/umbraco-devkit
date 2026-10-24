"""Folders and files as the page shows them: the path trail, the file list, reading order,
where a comment sits in its file, and when a page needs redrawing."""
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


def folder_listing(folder, url_path, current, counts, home="/"):
    """The file list: folders first, as on GitHub; then files in the README's reading order;
    then the rest by name. No way up from the top of the scope."""
    entries = [e for e in os.scandir(folder) if not e.name.startswith(".")]
    order = reading_order(folder)
    entries.sort(key=lambda e: (not e.is_dir(), e.name not in order,
                                order.index(e.name) if e.name in order else 0, e.name.lower()))
    rows = []
    if url_path not in ("/", home):
        rows.append(f'<a href="{urllib.parse.quote(url_path)}..">{ICON_DIR}..</a>')
    for e in entries:
        href = urllib.parse.quote(url_path + e.name) + ("/" if e.is_dir() else "")
        cls = ' class="current"' if e.name == current else ""
        count = counts.get(url_path + e.name)
        dot = f'<span class="dot" title="Open comments">{count}</span>' if count else ""
        rows.append(f'<a href="{href}"{cls}>{ICON_DIR if e.is_dir() else ICON_FILE}{html.escape(e.name)}{dot}</a>')
    return f'<div class="box files">{"".join(rows)}</div>'


def doc_position(root, comment, sources=None):
    """A sort key putting comments in reading order: [folder, file's rank in its README,
    file, offset in the file]. The offset is where the first words of the comment's text
    appear in the Markdown, allowing for formatting between them; failing that, its section
    heading; failing that, the end of the file."""
    sources = {} if sources is None else sources
    path = os.path.join(root, comment["path"].lstrip("/"))
    folder, name = os.path.dirname(path), os.path.basename(path)
    order = reading_order(folder)
    if path not in sources:
        try:
            with open(path, encoding="utf-8") as f:
                sources[path] = f.read()
        except OSError:
            sources[path] = ""
    text = sources[path]
    for probe in (comment.get("original") or comment["quote"], comment["quote"], comment.get("section", "")):
        words = re.findall(r"\w+", probe or "")[:5]
        m = words and re.search(r"\W+".join(map(re.escape, words)), text)
        if m:
            return [folder, order.index(name) if name in order else len(order), name, m.start()]
    return [folder, order.index(name) if name in order else len(order), name, len(text)]


def change_marker(path):
    """Something that changes whenever the page for `path` needs redrawing: the folder's file
    names, and the shown file's (or a folder's README's) modified time."""
    try:
        folder, doc = (path, os.path.join(path, "README.md")) if os.path.isdir(path) else (os.path.dirname(path), path)
        names = tuple(sorted(e.name for e in os.scandir(folder)))
        return (names, os.stat(doc).st_mtime_ns if os.path.isfile(doc) else None)
    except FileNotFoundError:
        return None  # editors sometimes delete and rewrite on save
