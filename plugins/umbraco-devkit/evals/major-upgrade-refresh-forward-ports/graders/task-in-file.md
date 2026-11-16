---
type: llm
weight: 1
focus: {source: file, path: docs/upgrades/v19.md}
---
PASS if the upgrade file's task list has a new unchecked task to bring the older line's #212
fix (stock level for products without variants) onto the v19 line, and still targets
`release-19.0.0-rc1`.

FAIL if there is no such task, or the file still targets `release-19.0.0-beta1`.
