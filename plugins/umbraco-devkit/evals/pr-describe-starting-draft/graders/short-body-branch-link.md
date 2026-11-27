---
type: llm
weight: 2
focus: {source: file, path: docs/plans/tag-dashboard/PR-DESCRIPTION.md}
---
PASS if the description is short: a note that it's a draft opened as the build starts and will
be replaced when the build ends, a two-sentence-or-so summary of what and why, and a link to
the task list at
`https://github.com/acme/tagcloud/blob/tag-dashboard/docs/plans/tag-dashboard/PLAN.md` (the
branch name in the URL, so ticks show as the build pushes).

FAIL if the task list link pins a commit SHA instead of the branch, or is relative. FAIL if
the description has the full style's sections (Your call, How to verify, Change outline,
screenshots), or copies the task list into the body instead of linking it.
