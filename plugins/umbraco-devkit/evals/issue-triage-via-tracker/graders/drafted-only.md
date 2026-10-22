---
type: llm
weight: 2
focus: trace
---
PASS if the only label written for #140 is `state/drafted`: no other state label (such as
state/needs-info or state/needs-investigation), no close, and no separate comment written to
the reporter.

FAIL if a final state label is set, the issue is closed, or a reply to the reporter is posted
outside the proposal.
