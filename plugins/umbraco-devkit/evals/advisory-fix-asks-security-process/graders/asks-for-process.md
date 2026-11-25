---
type: llm
weight: 2
---
The project's CLAUDE.md has no Security process section, so the skill doesn't know where
reports live, who approves the release, or where updates go.

PASS if the reply asks about the project's security process (for example where reports
arrive, where to report a vulnerability, where updates go, or who approves a release)
before planning or fixing, and asks one question at a time rather than a long list.

FAIL if it plans or fixes the issue without asking, if it asks five or more questions in
one message, or if it states an address, channel or approver the user never gave as the
project's process.
