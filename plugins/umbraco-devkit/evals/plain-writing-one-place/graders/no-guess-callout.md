---
type: regex
pattern: '\[!IMPORTANT\]'
match: not_contains
target: {source: file, path: docs/getting-started.md}
---
