---
type: llm
focus: {source: file, path: docs/plans/subscriber-export/SPEC.md}
---
Context: the brief gives one number (about 60,000 members) and no response-time, throughput
or memory figures. Look only at the feature's performance or scale targets (response times,
total run time, memory or query-count limits, data volumes), wherever SPEC.md states them.
API contract values such as a `take` default or its allowed range are not targets; ignore
them.

PASS if each such target that uses a figure the brief didn't give is marked as an
assumption for the human to confirm (for example `> ASSUMPTION:`, on the target or in one
note covering the targets).

FAIL if any such target states an invented figure as settled with no assumption marker, or
SPEC.md states no such targets at all.
