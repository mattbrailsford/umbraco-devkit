#!/usr/bin/env python3
"""Flags styling a mockup invented instead of taking from UUI or _mockup.css.

Compares each mockup with the starter it was copied from and checks only the lines the
mockup added, so the starter's own chrome is never flagged. Local stylesheets a mockup links
(other than _mockup.css) are checked too, each once, against the starter and the stylesheets
it links. What it flags on those lines:

- custom CSS: a new rule or declaration in a <style> block or linked stylesheet
- an inline style="..." attribute
- a raw colour (#hex, rgb(), hsl()) instead of a UUI colour variable
- !important
- a bare <h1>-<h6> with no class, which falls back to the browser's default size

A line, or a CSS rule's opening line, that carries a `mockup-ok: <reason>` comment is
skipped: for styling copied from the product's real source, say where from. Pages that don't
load _mockup.js (email mockups) are skipped, since inline styles and raw colours are how email
is written.

Usage: check_mockup.py --starter <starter.html> <mockup.html> [<mockup.html> ...]
Exit code: 0 if nothing was flagged, 1 if something needs a fix or a reason, 2 on bad input.
"""
import argparse
import os
import re
import sys

OK_MARKER = re.compile(r"mockup-ok:\s*\w")
LINK_TAG = re.compile(r"<link\b[^>]*>", re.I)
HREF = re.compile(r"\bhref\s*=\s*[\"']([^\"']+)[\"']", re.I)
LOADS_HARNESS = re.compile(r"<script\b[^>]*\bsrc\s*=\s*[\"'][^\"']*_mockup\.js[\"']", re.I)
STYLE_OPEN = re.compile(r"<style\b[^>]*>", re.I)
STYLE_CLOSE = re.compile(r"</style>", re.I)
SCRIPT_OPEN = re.compile(r"<script\b[^>]*>", re.I)
SCRIPT_CLOSE = re.compile(r"</script>", re.I)
INLINE_STYLE = re.compile(r"\sstyle\s*=\s*(\"[^\"]*\"|'[^']*')", re.I)
COLOUR_ATTR = re.compile(r"\s(?:fill|stroke|color|bgcolor|stop-color)\s*=\s*(\"[^\"]*\"|'[^']*')", re.I)
RAW_COLOUR = re.compile(r"(?<![\w&-])#[0-9a-fA-F]{3,8}\b|\b(?:rgba?|hsla?)\(", re.I)
IMPORTANT = re.compile(r"!\s*important", re.I)
BARE_HEADING = re.compile(r"<h[1-6](?=[\s>])(?![^>]*\bclass\s*=)[^>]*>", re.I)

HINTS = {
    "custom CSS rule": "use a UUI element or a _mockup.css class instead",
    "custom CSS": "use a UUI element or a _mockup.css class instead",
    "inline style": "use a UUI element, a _mockup.css class, or the component's own attribute",
    "raw colour": "use a --uui-color-* variable, with no colour fallback",
    "!important": "find what the rule is fighting instead of overriding it",
    "bare heading": "use the starter's heading (box headline, .headline) or a property label",
}


def starter_lines(path):
    """Every line of the starter and of the local stylesheets it links."""
    known = set()
    for source in [path] + linked_stylesheets(path):
        known |= {line.strip() for line in read_lines(source) if line.strip()}
    return known


def strip_css_comments(text, in_comment):
    """Removes /* ... */ from one line of CSS. Returns (text, still inside a comment)."""
    out = ""
    while text:
        if in_comment:
            end = text.find("*/")
            if end < 0:
                return out, True
            text, in_comment = text[end + 2:], False
        else:
            start = text.find("/*")
            if start < 0:
                return out + text, False
            out, text, in_comment = out + text[:start], text[start + 2:], True
    return out, in_comment


def read_lines(path):
    with open(path, encoding="utf-8") as f:
        return f.read().splitlines()


def linked_stylesheets(path):
    """The local stylesheets a page links, other than _mockup.css, as paths on disk."""
    found = []
    for line in read_lines(path):
        for tag in LINK_TAG.findall(line):
            href = HREF.search(tag)
            if not href or not re.search(r"rel\s*=\s*[\"']?stylesheet", tag, re.I):
                continue
            href = href.group(1)
            if re.match(r"^(?:[a-z]+:)?//", href, re.I) or os.path.basename(href) == "_mockup.css":
                continue
            found.append(os.path.normpath(os.path.join(os.path.dirname(path), href)))
    return found


def check(path, known):
    """Returns (findings, skipped). A finding is (line number, kind, snippet)."""
    lines = read_lines(path)
    if not any(LOADS_HARNESS.search(line) for line in lines):
        return [], True
    return scan(lines, known, css_file=False), False


def check_stylesheet(path, known):
    """Checks a stylesheet a mockup links, the same way as a <style> block in the page."""
    return scan(read_lines(path), known, css_file=True)


def scan(lines, known, css_file):
    findings = []
    in_style, in_script, in_comment = css_file, False, False
    rule_new = rule_ok = False  # the CSS rule the current line sits in
    for number, line in enumerate(lines, 1):
        text = line.strip()
        opens_style = not css_file and bool(STYLE_OPEN.search(line))
        if not css_file and SCRIPT_OPEN.search(line):
            in_script = True
        if in_script:
            in_script = not SCRIPT_CLOSE.search(line)
            continue
        css_part = STYLE_OPEN.split(line)[-1] if opens_style else line
        css_part = STYLE_CLOSE.split(css_part)[0]
        styled = in_style or opens_style
        if styled:
            css_part, in_comment = strip_css_comments(css_part, in_comment)

        if styled and "{" in css_part:
            rule_new = text not in known
            rule_ok = bool(OK_MARKER.search(line))
        added = text and text not in known and not OK_MARKER.search(line)

        if styled and css_part.strip() and added and not rule_ok:
            if "{" in css_part:
                selector = css_part.split("{")[0].strip()
                findings.append((number, "custom CSS rule", selector))
            elif not rule_new and ":" in css_part:
                findings.append((number, "custom CSS", css_part.strip()))
        if added and not (styled and rule_ok):
            colour_text = [css_part] if styled else []
            colour_text += [m.group(1) for m in INLINE_STYLE.finditer(line)]
            colour_text += [m.group(1) for m in COLOUR_ATTR.finditer(line)]
            for m in INLINE_STYLE.finditer(line):
                findings.append((number, "inline style", m.group(1).strip("\"'")))
            for chunk in colour_text:
                for m in RAW_COLOUR.finditer(chunk):
                    findings.append((number, "raw colour", chunk.strip().strip("\"'")))
                    break
            if IMPORTANT.search(css_part if styled else line):
                findings.append((number, "!important", text))
            for m in BARE_HEADING.finditer(line):
                findings.append((number, "bare heading", m.group(0)))

        if styled and "}" in css_part:
            rule_new = rule_ok = False
        if opens_style:
            in_style = True
        if in_style and not css_file and STYLE_CLOSE.search(line):
            in_style = False
    return findings


def report(path, findings):
    for number, kind, snippet in findings:
        print(f"{path}:{number}: {kind}: {snippet[:80]} ({HINTS[kind]})")
    return len(findings)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--starter", required=True, help="the starter the mockups were copied from")
    parser.add_argument("mockups", nargs="+")
    args = parser.parse_args(argv)
    try:
        known = starter_lines(args.starter)
    except OSError as e:
        print(f"Can't read the starter: {e}", file=sys.stderr)
        return 2

    total = 0
    stylesheets = []
    try:
        for path in args.mockups:
            findings, skipped = check(path, known)
            if skipped:
                print(f"{path}: skipped, it doesn't load _mockup.js (an email mockup?)")
            else:
                stylesheets += [s for s in linked_stylesheets(path) if s not in stylesheets]
            total += report(path, findings)
        for path in stylesheets:
            total += report(path, check_stylesheet(path, known))
    except OSError as e:
        print(f"Can't read {e.filename}: {e.strerror}", file=sys.stderr)
        return 2

    if total:
        print(f"\n{total} to fix, or to keep with a `mockup-ok: <reason>` comment on the line "
              "(for a CSS rule, on its opening line) naming the real source it was copied from.")
        return 1
    print("Nothing flagged.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
