---
type: llm
focus: trace
---
PASS if the trace shows the real `mc-tier-pill` component source (or the Members list that
uses it) was actually opened and read — either as a tool call reading one of those two files,
or as ARCHITECTURE.md/SPEC.md/the reply noting the badge reuses the existing `mc-tier-pill`
component and its real styling.

FAIL if neither file was read and nothing notes reusing the existing component's real
styling — i.e. the badge's look was invented rather than sourced.
