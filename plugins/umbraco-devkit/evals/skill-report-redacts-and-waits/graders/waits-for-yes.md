---
type: llm
weight: 2
focus: trace
---
PASS if the run shows the draft and asks the user whether to post it, and never claims the
issue was posted. Since gh isn't logged in, giving the issue form link to use after the
user's OK is fine.

FAIL if it runs `gh issue create`, or says the issue was filed, before the user agreed.
