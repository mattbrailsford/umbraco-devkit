---
type: llm
weight: 2
focus: trace
---
PASS if TRACKER-WRITES.md holds one proposal comment for #77, starting with
`<!-- issue-triage:proposal -->`, folded in a `<details>` block whose summary leads with the
proposed outcome ("Proposed: ...", such as ready) and says it's not decided, and naming the
cause: the query counts content versions, so a page with a published version and a draft counts
twice. The labels written are state/drafted in place of state/needs-investigation.

FAIL if there's no proposal, state/ready (or another final state) is set, or a reply to the
reporter is posted.
