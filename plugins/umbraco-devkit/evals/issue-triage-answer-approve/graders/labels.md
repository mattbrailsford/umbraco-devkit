---
type: llm
weight: 2
focus: {source: file, path: TRACKER-WRITES.md}
---
PASS if the writes add `state/needs-info` to #140 and remove `state/drafted`, and don't close
it (@kai-dev has no write access, so their comment isn't an answer).

FAIL if a label is missing or wrong, state/drafted stays, or the issue is closed.
