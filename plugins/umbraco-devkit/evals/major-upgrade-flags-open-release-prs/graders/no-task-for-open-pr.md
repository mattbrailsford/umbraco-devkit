---
type: llm
focus: {source: file, path: docs/upgrades/v19.md}
---
CMS PR #99870 (`IApiContentResponseBuilder.Build` becomes `BuildAsync`) is still open and
isn't in `release-19.0.0-rc1`, the release this upgrade targets.

PASS if this file's task list has no task that changes `StockContentResponseBuilder` to
`BuildAsync` or otherwise builds against #99870's change now. A note, watch-list entry, or
follow-up about it is fine.

FAIL if a task in the task list makes that change against rc1, or the file doesn't exist.
