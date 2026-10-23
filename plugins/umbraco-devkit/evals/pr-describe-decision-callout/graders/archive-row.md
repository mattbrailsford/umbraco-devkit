---
type: regex
weight: 2
pattern: '> \|[^\n]*(?:redirectsDeleted|DeletedRedirectArchive|AddDeletedRedirectsTable)[^\n]*\*\(recommended\)\*\s*<br>'
target: {source: file, path: docs/plans/bulk-delete/PR-DESCRIPTION.md}
---
