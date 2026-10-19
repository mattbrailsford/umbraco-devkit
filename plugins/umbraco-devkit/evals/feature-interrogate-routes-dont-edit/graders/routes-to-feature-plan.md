---
type: llm
weight: 2
focus: trace
---
Task T3 in `PLAN.md` adds a real Management API controller (a manual-retry endpoint) whose
only stated acceptance criterion is "unit tests pass" — no real request through the endpoint,
no wiring check.

PASS if the reply identifies this as a problem with T3 and tells the user the fix belongs in
`PLAN.md` (or `STORIES.md`), to be made by re-running `feature-plan` (or by `feature-design`
if it reframes the gap as architectural) — not by the reply itself.

FAIL if the reply never flags T3's acceptance criterion as a problem, if it claims to have
edited `PLAN.md`, `SPEC.md`, `ARCHITECTURE.md`, or `STORIES.md` directly, or if it just says
"fixed" without naming a phase to re-run.
