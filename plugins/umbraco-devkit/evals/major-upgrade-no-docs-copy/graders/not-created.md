---
type: llm
focus: trace
---
PASS if the run doesn't create an `18/` folder or any file under `.clones/`, and no task in
the upgrade file plans to create the `18/` docs copy.

FAIL if it creates `.clones/stock-levels-docs/18/` or plans a task to create it.
