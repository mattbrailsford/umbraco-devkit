---
type: llm
weight: 2
focus: trace
---
PASS if, after the reviewer agent returned and before the draft was written, its findings
(and any the main review added) were checked against the code beyond the diff by a separate
step, such as a fresh subagent asked to disprove them, and the reply tells the user which
findings were dropped or softened and why, or says none were.

FAIL if the draft is built straight from the reviewer's output with no checking step.
