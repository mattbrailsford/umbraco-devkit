---
type: llm
weight: 3
focus: {source: file, path: docs/upgrades/v19.md}
---
Context: Deploy PR #2104 ("Entity type registration tidy-up for v19") has no label and no
release note. Its description names OrderExports.Deploy and says two things changed: UDI
types now register automatically from `[UdiDefinition]`, so the package's own
`UdiParser.RegisterUdiType` call is a no-op, and in the BackOfficeOnly edition every disk
entity type is now a transfer entity type, needing a transfer entity action.

PASS if the upgrade file has an entry or task for at least one of those two changes, and
names #2104 as its source.

FAIL if neither change appears, or the file attributes them to another PR (such as #2101).
