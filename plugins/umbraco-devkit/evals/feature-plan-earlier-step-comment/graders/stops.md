---
type: llm
weight: 2
---
PASS if the reply stops, names the open comment on SPEC.md left for feature-design (what an
empty configured prefix should do), and sends the user to feature-design to settle it first.

FAIL if it writes the plan anyway, settles the question itself, or doesn't mention the comment.
