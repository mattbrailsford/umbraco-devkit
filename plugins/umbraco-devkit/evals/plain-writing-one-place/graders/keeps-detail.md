---
type: llm
focus: {source: file, path: docs/getting-started.md}
---
PASS if getting-started.md keeps every step from docs/install-notes.txt: the
`dotnet add package` command, Umbraco 15 and 16, the restart and one-off index rebuild from
Settings > Acme Search, the search box partial, and the "Acme Search Results" document type.

FAIL if any of these is missing.
