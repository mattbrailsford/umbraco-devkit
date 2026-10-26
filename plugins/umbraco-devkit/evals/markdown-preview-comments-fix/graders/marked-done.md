---
type: llm
weight: 2
focus: trace
---
PASS if the run replied on comment c1 with the skill's script (`preview.py reply c1 ...`) and
passed `--done`, with a reply that says what changed.

FAIL if it never replied through the script, replied without `--done`, or used `--defer`.
