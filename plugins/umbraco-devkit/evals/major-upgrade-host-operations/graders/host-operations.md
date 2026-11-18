---
type: llm
weight: 3
focus: {source: file, path: docs/upgrades/v19.md}
---
Context: OrderExports.Deploy adds a Deploy service connector for export profiles. Deploy
runs its own operations on those profiles: transfer to another environment, restore
(including partial restore), export and import, in more than one edition (such as
BackOfficeOnly).

PASS if the upgrade file lists Deploy's own operations on export profiles for the smoke to
run, covering at least transfer, partial restore and the BackOfficeOnly edition (or
"each Deploy edition").

FAIL if the smoke only covers what the package adds (for example "export profiles still
deploy" in one line), or leaves out partial restore or the other edition.
