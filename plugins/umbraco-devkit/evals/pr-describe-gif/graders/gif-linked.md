---
type: llm
weight: 2
focus: {source: file, path: docs/plans/gallery-sorting/PR-DESCRIPTION.md}
---
The plan folder has a recorded GIF, `screenshots/gallery-items-reorder.gif`, showing an item
being dragged to the top.

PASS if the description embeds that GIF as an image (`![...](...)`, not a plain link) using a
full URL of the form
`https://github.com/acme/Umbraco.Community.Gallery/blob/9f8e7d6c5b4a39281706f5e4d3c2b1a098765432/docs/plans/gallery-sorting/screenshots/gallery-items-reorder.gif?raw=true`.

FAIL if the GIF is missing, linked by a relative path, linked to a branch name instead of the
commit, or only mentioned in text.
