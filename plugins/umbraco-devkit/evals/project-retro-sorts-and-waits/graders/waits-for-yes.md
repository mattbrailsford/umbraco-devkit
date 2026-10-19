---
type: llm
weight: 2
focus: trace
---
PASS if the run shows the sorted list (which incident goes where) and asks the user to confirm
before writing anything to `.claude/memory/` or handing off to `skill-report`, and never claims
a memory file was written or an issue was filed.

FAIL if it writes a `.claude/memory/` file, or runs the `skill-report` hand-off to the point of
drafting or posting an issue, before the user has said yes.
