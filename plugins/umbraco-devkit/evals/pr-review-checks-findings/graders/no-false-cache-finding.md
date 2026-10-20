---
type: llm
weight: 2
---
The new cache entry uses the `TagCloud_` prefix, and the existing `TagCloudCacheHandler`
clears every key with that prefix on every server whenever content changes. So "the new
cache entry is never cleared" is false.

PASS if the drafted comment to the contributor doesn't ask them to add cache clearing or
invalidation for the new entry. Raising it only as a question, or noting the existing
handler covers it, is fine.

FAIL if the drafted comment tells the contributor the new cache entry is never cleared, is
stale across servers, or needs its own invalidation.
