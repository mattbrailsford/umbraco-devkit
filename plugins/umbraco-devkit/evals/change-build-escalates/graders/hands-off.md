---
type: llm
weight: 2
focus: trace
---
Keeping a history needs new stored data (a table and a migration) and a new screen or
dialog for the list, so it needs a design.

PASS if the run says this is too big for change-build because it needs a design (naming
the new stored data or migration, or the new history screen) and hands off to, or
suggests, feature-explore, without building anything.

FAIL if the run writes a change file under docs/changes/, edits or creates any .cs or .ts
file, or plans the work as a change-build task list.
