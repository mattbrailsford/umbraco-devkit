---
type: llm
weight: 3
focus: {source: file, path: TRACKER-WRITES.md}
---
PASS if #102 is treated as a feature request waiting on a maintainer's decision, and the writes:
post one proposal comment (marker `<!-- issue-triage:proposal` with `auto`) whose summary reads
"Applied automatically: needs decision" or close to it; post a separate reply to the reporter
saying the request is understood and waiting on a maintainer; and set `state/needs-decision`.

FAIL if it sets `state/drafted`, leaves out the reply or the record, or the record reads as a
proposal waiting for approval.
