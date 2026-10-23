{Optional header row — only if you have real links: a ticket, a plan-folder link, a related PR.
Omit the whole line if there's nothing to link.}

[{Ticket ID}]({ticket_url}) | [{Plan folder}]({plan_folder_link}) | ...

{Stacked PR only — omit entirely otherwise: `Stacked on #<parent-pr-number>.`}

## Why the change

{Exactly one sentence: the problem this PR solves and what becomes possible once it ships.}

## What it looks like

{Only when the PR adds or changes backoffice UI. Omit the whole section otherwise.}

**Where to find it:** {Section › tree item › … › tab, one line per new or changed screen}

**Who can see it:** {the section, user group or permission that grants access, in plain words}

{New screen: the built screenshot.}

![{Screen name}](https://github.com/{owner}/{repo}/blob/{sha}/{plan-folder}/screenshots/{screen}.png?raw=true)

{Changed screen: before and after side by side.}

| Before | After |
|---|---|
| ![{Screen name} before](https://github.com/{owner}/{repo}/blob/{sha}/{plan-folder}/screenshots/{screen}-before.png?raw=true) | ![{Screen name} after](https://github.com/{owner}/{repo}/blob/{sha}/{plan-folder}/screenshots/{screen}.png?raw=true) |

{Interaction GIF, only if one is in screenshots/: a one-line caption, then the GIF, under its
screen's screenshot.}

{What the GIF shows, e.g. "Dragging a gallery item to the top."}

![{Screen name}: {action}](https://github.com/{owner}/{repo}/blob/{sha}/{plan-folder}/screenshots/{screen}-{action}.gif?raw=true)

## Special things to note

- {Every `Needs a decision`/`Consider reverting` item decision-review flagged, first, each
  prefixed with its verdict — e.g. "**Needs a decision:** {what and why}" or "**Consider
  reverting:** {what and why}". A plain `Looks fine as documented` item gets no prefix.}
- {Then one bullet each for migrations, compatibility constraints, or other deliberate
  omissions decision-review wouldn't have caught — no fixed count, but each one must be
  something the reviewer genuinely needs before approving, not a restatement of the change
  outline below. Write "- None." if there's nothing at all.}

## Change outline

{Use the smallest combination of views from references/diagram-conventions.md that explains
the implementation. Only include a view that actually changed — omit the rest. Order them
however tells the story best; a data structure or contract usually comes before the code that
uses it.}

{Plan-folder diagrams first, if diagrams/ has any that match what was built: a one-line
caption, then the image by full URL.}

{What the diagram shows, e.g. "How a delivery moves from publish to delivered."}

![{Diagram name}](https://github.com/{owner}/{repo}/blob/{sha}/{plan-folder}/diagrams/{name}.svg?raw=true)

{...one short sentence introducing the view...}

```diff
{the diagram}
```

{Repeat for each relevant view — file tree, component tree, call chain, table/contract diff,
manifest registration diff, backoffice registrations table, settings, API endpoints,
pseudocode. Prefer `diff` for a change to an existing shape; show
the whole block only when most of it is new or a diff would hide ownership or order.}
