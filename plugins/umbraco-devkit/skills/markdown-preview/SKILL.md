---
name: markdown-preview
description: >-
  Opens a Markdown file or folder in the browser as GitHub will show it, drawn by GitHub's own
  renderer, and refreshes the page as the file changes. Alerts, task lists, tables, footnotes,
  Mermaid, math and local images all show as they will on GitHub. A folder opens GitHub-style,
  with its file list beside its README. Use when the user asks to see, show, open, view or
  preview a doc: "show me the brief", "open the plan", "let me see the spec", "preview the PR
  description". Also owns when a phase that writes a plan file offers a preview.
user-invocable: true
argument-hint: [file or folder, optional]
---

# markdown-preview

Show a doc the way GitHub will, while it's still on disk. GitHub turns the Markdown into HTML,
so what the reader sees here is what they'll see in a PR or on the repo. The page refreshes in
place each time the file is saved, so the user can say "fix X", watch it change, and keep
their place.

## Pick what to open

- **"The brief", "the spec", "the plan's tasks"**: that file in the current feature's plan
  folder. Find the folder the way the pipeline does (see `CLAUDE.md`'s "Finding the current
  feature's plan folder"). Ask only if it's still ambiguous.
- **"The plan", "the plan folder"**: the folder itself. Its page lists every file beside its
  `README.md`, the read-order index, so the user can click through the whole plan.
- **A named file or folder**: that one.
- **Nothing named**: the file you last wrote or the user last mentioned in this session.

## Open it

Run `scripts/preview.py` from this skill's folder with the path, as a background command:

```bash
python3 <this skill's folder>/scripts/preview.py <file-or-folder>
```

- It prints the page's URL and opens it in the user's browser. Give them the URL.
- **One server per git worktree.** If one is already running for that worktree, the script
  opens the new page on it and exits straight away. Don't stop a running server to open
  another file.
- The server stops when the session ends, when it's killed, or once its worktree folder is
  removed.
- A file outside any git repo is served from its own folder.

## Offering a preview

A phase that writes a doc a person reviews (`BRIEF.md`, `ARCHITECTURE.md`, `SPEC.md`,
`PLAN.md`) offers to open it in its Hand off, before the suggested next step:

- **First time this session:** one line, such as "Open BRIEF.md in a live preview? It sends
  the file's text to GitHub to be drawn." Then carry on. It's an offer, not a stop.
- **A preview is already open in this worktree:** don't ask. Open the new file on it and say
  the page is up.
- **The user said no earlier this session:** don't offer again.

## *What it needs*

- macOS, `python3` (part of Xcode's command line tools, which git already needs) and `gh`,
  signed in. `gh auth status` says whether it is.
- Internet access: GitHub draws the page, and the styles, Mermaid and math load from a CDN.
- The file's text goes to GitHub's Markdown API, including unsaved plans that aren't
  committed. Nothing else is sent anywhere.

## *How close it is to GitHub*

- **Drawn by GitHub:** headings, alerts, tables, task lists, footnotes, code colours, `#123`
  issue links for the repo, and remote images through GitHub's image proxy.
- **Copied from GitHub in the page:** the styles (the `github-markdown-css` package), heading
  anchors, Mermaid and math. Spacing or a diagram's layout can differ by a few pixels.
- **Local images, SVGs included,** load from the worktree. One that's broken here will be
  broken on GitHub too.
- If GitHub can't be reached or `gh` isn't signed in, a red note shows in the page's corner.
