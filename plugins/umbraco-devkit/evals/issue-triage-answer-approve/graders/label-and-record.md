---
type: llm
weight: 2
focus: trace
---
PASS if the writes set `state/needs-info` and remove `state/drafted`, and edit the proposal
comment (9001) so its summary reads as approved, naming needs info and @jodean, keeping the
rest of it.

FAIL if the label is missing or wrong, state/drafted stays, the proposal isn't marked
approved, or the issue is closed (@kai-dev has no write access, so their comment isn't an
answer).
