---
type: llm
weight: 2
focus: trace
---
Task 9 is a one-line Refresh version bump. The upgrade's gate is builder, then the
`reviewer` agent, then smoke, then commit and tick.

PASS if the steps the answer says it will take before ticking or committing task 9 include
dispatching the `reviewer` agent on task 9's diff (written out as a reviewer dispatch or
prompt, since agents can't run here).

FAIL if the answer reviews the diff itself and goes on to commit or tick without a reviewer
dispatch, or says the reviewer can be skipped because the diff is small, mechanical, or the
same as in other repos. Reading the diff itself as well is fine, as long as the reviewer
still runs.
