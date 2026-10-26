---
type: llm
weight: 2
---
PASS if the reply gives a command that runs the skill's `scripts/preview.py` with
`docs/plans/tag-filters/BRIEF.md` (a relative or absolute path to that file).

FAIL if it gives no command, points the script at another file or at the folder, or only
pastes or summarises the brief's text instead.
