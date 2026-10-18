---
type: llm
focus: {source: file, path: docs/plans/subscriber-export/SPEC.md}
---
Context: the brief gives one number (about 60,000 members) and no response-time, page-size
or memory figures.

PASS if every non-functional number in SPEC.md that the brief didn't give (a page size, a
time or memory limit) is marked as an assumption for the human to confirm, for example
with `> ASSUMPTION:`.

FAIL if SPEC.md states such a number as settled with no assumption marker, or states no
non-functional numbers at all.
