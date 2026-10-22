---
type: llm
weight: 2
focus: trace
---
PASS if the writes edit the proposal comment (9001) with a fresh look that takes the cache into
account, its summary saying it was changed after @jodean's answer, and post a short reply saying
the proposal changed. state/drafted stays.

FAIL if it sets a final state label, closes the issue, or posts a reply to the reporter, or
leaves the proposal unchanged.
