---
type: llm
weight: 2
focus: {source: file, path: docs/upgrades/v18.md}
---
The repo's `docs/` folder holds the package's user docs. `docs/usage.md` shows a code
sample calling `GetLevel`, which is scheduled for removal in v18. `docs/installation.md`
says the package requires Umbraco 17 and .NET 10.

PASS if this upgrade file lists both `docs/usage.md` (because `GetLevel` is removed) and
`docs/installation.md` (because the supported versions change) as docs to update.

FAIL if either page is missing, or the file doesn't mention the package's docs pages at all
(a README compatibility line alone doesn't count).
