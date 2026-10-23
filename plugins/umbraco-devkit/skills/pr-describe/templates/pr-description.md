{Optional header row — only if you have real links: a ticket, a plan-folder link, a related PR.
Omit the whole line if there's nothing to link.}

[{Ticket ID}]({ticket_url}) | [{Plan folder}]({plan_folder_link}) | ...

{Stacked PR only — omit entirely otherwise: `Stacked on #<parent-pr-number>.`}

{Your call: every Your call item from decision-review, in its order. Omit the whole callout
when there are none. Every line starts with `> `.}

> [!IMPORTANT]
> **{N} choices were made without you.** Please check each one.
>
> | | Type | Plan said | Built | Options |
> |---|---|---|---|---|
> | 1 | {Design / Behavior / UI} | {what the plan said, or "Nothing about <topic>"} | [{what was built}](https://github.com/{owner}/{repo}/blob/{sha}/{path}#L{line}) | **A. {recommended option}** *(recommended)*<br>B. {other option} |
>
> **{n}. Mockup vs built**
>
> | Mockup | Built |
> |---|---|
> | ![Mockup](https://github.com/{owner}/{repo}/blob/{sha}/{plan-folder}/mockups/{screen}.png?raw=true) | ![Built](https://github.com/{owner}/{repo}/blob/{sha}/{plan-folder}/screenshots/{screen}.png?raw=true) |

{Mockup vs built: only for a UI item that departs from its mockup, one per item.}

{Must fix: only when decision-review returned Must fix items. Omit it otherwise.}

> [!CAUTION]
> **Must fix before merge**
>
> - [{what's broken}](https://github.com/{owner}/{repo}/blob/{sha}/{path}#L{line})

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

## How to verify

1. {A step on the demo site, and what the reviewer should see.}

## Good to know

{Only for a planned migration, a compatibility limit or a deliberate omission the reviewer
needs before approving. One line each. Omit the section when there's nothing.}

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

{Repeat for each relevant view — file tree, component tree, call chain, database table,
contract, manifest registration diff, backoffice registrations table, settings, API
endpoints, pseudocode. Prefer `diff` for a change to an existing shape; show the whole block
only when most of it is new or a diff would hide ownership or order. Tables never go in a
`diff` block; they mark changes in a `Change` column.}

{Checked and fine: decision-review's Checked and fine items, folded. Omit when there are none.}

<details>
<summary>Checked and fine ({count})</summary>

- {One line per item.}

</details>
