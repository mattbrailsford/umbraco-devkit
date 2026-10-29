---
type: llm
weight: 2
focus: {source: file, path: docs/getting-started.md}
---
docs/configuration.md already lists every setting with its default and range.

PASS if getting-started.md links to configuration.md for settings and does not repeat that
list: it may name at most two settings that a first install actually needs, but no table or
list of settings with their defaults or ranges.

FAIL if it repeats three or more settings with their defaults or ranges, or copies the
configuration table.
