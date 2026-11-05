---
type: llm
weight: 2
focus: {source: file, path: docs/upgrades/v18.md}
---
The package's docs live in a separate repo, cloned at `.clones/stock-levels-docs`, with one
copy per CMS major (`17/` and `18/`). Both copies' `usage.md` show `GetLevel`, which is
removed in v18, and both `installation.md` say Umbraco 17.

PASS if this upgrade file lists the docs pages to change from the `18/` copy (at least
`18/usage.md` for `GetLevel`), not only the `17/` copy.

FAIL if the docs aren't listed, or only `17/` pages are named.
