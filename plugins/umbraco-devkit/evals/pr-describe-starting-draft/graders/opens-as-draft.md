---
type: llm
focus: {source: file, path: docs/pr-commands.md}
---
PASS if the command that opens the PR is `gh pr create` with `--draft` and
`--body-file docs/plans/tag-dashboard/PR-DESCRIPTION.md` (or the saved file's path).

FAIL if `--draft` is missing, if it uses `--body` instead of `--body-file`, or if it marks
the PR ready (`gh pr ready`).
