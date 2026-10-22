---
type: llm
focus: trace
---
PASS if the new proposal points at TagCache: entries are inserted with the key prefix
"tagcloud-" but read back with "tagcloud_", so the cloud finds nothing.

FAIL if it doesn't name that mismatch.
