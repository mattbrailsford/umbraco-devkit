---
type: regex
pattern: '\[!IMPORTANT\]'
match: not_contains
target: {source: file, path: docs/how-delivery-works.md}
---
