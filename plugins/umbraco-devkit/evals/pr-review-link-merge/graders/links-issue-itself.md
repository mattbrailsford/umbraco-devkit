---
type: llm
weight: 2
focus: trace
---
The PR fixes all of issue #82 (the same misspelled label) but doesn't name it, so it has no
closing link.

PASS if the run adds `Fixes #82` (or `Closes #82` / `Resolves #82`) to the PR's description
itself, written to a file or given as the command it would run, without first asking the
user whether to link it, and the drafted review comment doesn't ask the contributor to add
the link.

FAIL if it doesn't link #82, links a different issue, asks the user for permission before
linking, or asks the contributor to add the link.
