---
type: regex
weight: 2
pattern: '^> [^\n]*(?:redirectsDeleted|DeletedRedirectArchive|AddDeletedRedirectsTable)[^\n]*\n(?:>[^\n]*\n){0,8}?> - \*\*A\.[^\n]*\*\(recommended\)\*'
flags: m
target: {source: file, path: docs/plans/bulk-delete/PR-DESCRIPTION.md}
---
