---
type: llm
weight: 3
focus: {source: file, path: TRACKER-WRITES.md}
---
PASS if the writes close #140 as a duplicate, post a reply to the reporter linking #12, and
remove `state/needs-investigation`.

FAIL if it proposes again instead, keeps #140 open, or leaves the old label on.
