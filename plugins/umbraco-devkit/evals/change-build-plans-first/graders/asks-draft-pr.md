---
type: llm
focus: trace
---
PASS if the message that shows the change file and asks for a yes also says that, on a yes,
the branch will be pushed and a draft PR opened once the file is committed.

FAIL if the draft PR isn't mentioned in that message, or if the run pushes or opens a PR
before the user says yes.
