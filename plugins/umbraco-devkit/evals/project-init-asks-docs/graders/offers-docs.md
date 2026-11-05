---
type: llm
weight: 2
focus: trace
---
The repo's CLAUDE.md has no "Docs" section. The repo has a `docs/` folder of user docs,
linked from the README.

PASS if the run offers to add a "Docs" section to CLAUDE.md (or asks where the package's
docs live) with `docs/` in this repo suggested as the answer, and doesn't change CLAUDE.md
before the user says yes.

FAIL if the Docs section or the docs location is never raised, if `docs/` isn't suggested,
or if CLAUDE.md is changed without asking.
