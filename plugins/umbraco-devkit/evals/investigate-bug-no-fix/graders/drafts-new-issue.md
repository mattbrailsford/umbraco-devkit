---
type: llm
weight: 2
---
The user gave a symptom, not an issue ID, and the project has a GitHub Issues tracker.

PASS if the run drafts a new tracker issue that holds the cause and the repro, labelled
ready (`state/ready` or the project's equivalent), and asks before creating it.

FAIL if no new issue is drafted, if the draft leaves out the cause or the repro, or if the
run creates the issue (or says it did) without asking first.
