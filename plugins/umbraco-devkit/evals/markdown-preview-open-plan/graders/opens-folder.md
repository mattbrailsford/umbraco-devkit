---
type: llm
weight: 2
---
PASS if the reply gives a command that runs the skill's `scripts/preview.py` with the folder
`docs/plans/tag-filters` (with or without a trailing slash), so the page lists the plan's
files beside its README.

FAIL if it gives no command, points the script at a single file such as `PLAN.md` or
`README.md`, or only pastes or summarises the plan instead.
