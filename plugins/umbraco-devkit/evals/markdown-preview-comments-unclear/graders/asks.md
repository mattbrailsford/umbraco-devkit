---
type: llm
weight: 2
focus: trace
---
PASS if the run replied on comment c1 with the skill's script (`preview.py reply c1 ...`)
asking what the reviewer wants, without `--done` or `--defer`, so the comment stays open.

FAIL if it marked c1 done or deferred it, or never replied through the script.
