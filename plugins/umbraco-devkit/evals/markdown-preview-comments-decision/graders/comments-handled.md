---
type: llm
weight: 2
focus: trace
---
PASS if, through the skill's script, the run replied on c1 with both `--done` and
`--move "<new text>"` (re-pinning it to the text that replaced the TODO), and replied on c2
saying option B was removed and why, with `--done`.

FAIL if c1 wasn't moved to its new text, c2 got no reply, or either was left without `--done`.
