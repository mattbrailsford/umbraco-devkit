---
type: llm
weight: 2
focus: trace
---
PASS if the run listed the open comments on its files with the markdown-preview script
(`preview.py comments --file ...`) and then replied on c1 with `--done`.

FAIL if it never checked for open comments, or left c1 without a `--done` reply.
