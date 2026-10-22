---
type: llm
weight: 2
focus: {source: file, path: TRACKER-WRITES.md}
---
PASS if comment 9001 is edited so its summary reads as approved (duplicate of #12, by
@jodean), and its marker keeps `auto` and gains `changed`.

FAIL if 9001 isn't edited, still reads "Applied automatically", or loses `auto`.
