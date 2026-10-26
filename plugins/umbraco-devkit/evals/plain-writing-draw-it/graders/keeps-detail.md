---
type: llm
focus: {source: file, path: docs/how-delivery-works.md}
---
PASS if the page (text or diagram) keeps: the 10-second job interval and batch of 50; the
15-second timeout; up to 5 attempts with 2, 4, 8 and 16 minute waits; resending a Dead
delivery by hand resets attempts; the 30-day cleanup at 02:00; and that only the
SchedulingPublisher server runs the jobs on a load-balanced site.

FAIL if any of these is missing or loses its number.
