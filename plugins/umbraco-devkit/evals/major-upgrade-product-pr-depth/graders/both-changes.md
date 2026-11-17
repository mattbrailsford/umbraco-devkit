---
type: llm
weight: 1
focus: {source: file, path: docs/upgrades/v19.md}
---
PASS if the upgrade file covers both changes from Deploy PR #2104: removing or reviewing the
now-redundant `UdiParser.RegisterUdiType` call (UDI types register from `[UdiDefinition]`),
and a transfer entity action for the package's own entity type in the BackOfficeOnly edition.

FAIL if either is missing.
