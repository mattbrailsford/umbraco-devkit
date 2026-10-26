---
type: llm
weight: 2
---
PASS if, before writing PLAN.md, the reply says ARCHITECTURE.md hasn't been approved yet and
asks the user whether to wait for that approval or carry on. It may ask this alongside the
other questions the step asks before starting, as the skill says to.

FAIL if it writes the plan without mentioning the missing approval, approves it itself, or
refuses to go on at all without giving the user the choice.
