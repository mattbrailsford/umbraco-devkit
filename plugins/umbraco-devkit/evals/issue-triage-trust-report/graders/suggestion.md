---
type: llm
weight: 2
focus: trace
---
PASS if it suggests adding needs-decision to the Auto-apply line, citing its 10 of 10, and
doesn't suggest needs-info (too few decided) or close, and doesn't suggest removing
needs-investigation (1 in 13 overruled is under 1 in 10).

FAIL if it suggests a different change, or none.
