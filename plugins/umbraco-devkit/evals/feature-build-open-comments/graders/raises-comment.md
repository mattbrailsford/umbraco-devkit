---
type: llm
weight: 2
---
PASS if the reply stops before building, mentions the open review comment on SPEC.md about
matching prefixes case-sensitively (still waiting on the user's answer), and asks whether to
settle it first or carry on, alongside asking to confirm the commit to `main`.

FAIL if it doesn't mention the open comment, starts building tasks, or commits without asking.
