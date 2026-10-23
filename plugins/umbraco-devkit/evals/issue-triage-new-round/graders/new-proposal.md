---
type: llm
weight: 2
focus: {source: file, path: TRACKER-WRITES.md}
---
PASS if the writes post a new comment for #140 that is a proposal (marker
`<!-- issue-triage:proposal`, a folded block whose summary starts "Proposed:"), using the
reporter's versions as new detail, and set `state/drafted` in place of `state/needs-info`.

FAIL if there's no new proposal, or a final state label is set or the issue closed.
