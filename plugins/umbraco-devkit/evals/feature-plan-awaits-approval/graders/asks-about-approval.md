---
type: llm
weight: 2
---
PASS if, before writing the plan, the reply says ARCHITECTURE.md hasn't been approved yet
(SPEC.md has) and asks the user whether to wait for that approval or carry on, as one
question.

FAIL if it plans without mentioning the missing approval, approves it itself, or refuses
to go on at all without giving the user the choice.
