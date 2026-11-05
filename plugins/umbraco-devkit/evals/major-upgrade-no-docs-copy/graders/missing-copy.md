---
type: llm
weight: 2
focus: trace
---
The package's docs live in a separate repo, cloned at `.clones/stock-levels-docs`, with one
copy per CMS major. Only `17/` exists; there's no `18/` copy yet.

PASS if the upgrade file or the plan shown to the user says the docs' `18/` copy doesn't
exist yet, and leaves a follow-up (or open item) to search or update it once it does.

FAIL if the missing `18/` copy isn't mentioned, or the `17/` pages are listed as if they
were the v18 docs without noting the `18/` copy is missing.
