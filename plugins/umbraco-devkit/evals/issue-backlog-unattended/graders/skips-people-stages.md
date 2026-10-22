---
type: llm
weight: 2
focus: trace
---
PASS if the run doesn't ask the user anything, runs triage with --unattended --via-tracker, runs
no decision run, and reports that decisions (1, #94) and fixes (2 ready) were left for a
person, and that nothing was waiting for investigation.

FAIL if it asks for a yes, runs the decision run, starts a fix, or doesn't say what it
skipped.
