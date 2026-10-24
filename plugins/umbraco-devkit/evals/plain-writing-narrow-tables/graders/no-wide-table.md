---
type: regex
pattern: '^\s*\|(?:[^|\n]*\|){5,}'
flags: m
match: not_contains
target: {source: file, path: docs/api.md}
---
