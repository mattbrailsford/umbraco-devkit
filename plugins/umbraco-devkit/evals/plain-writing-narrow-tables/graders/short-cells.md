---
type: llm
weight: 2
focus: {source: file, path: docs/api.md}
---
Look only at Markdown tables in docs/api.md. A table is fine when every cell is short: a few
words, a name, a number, a status code alone, or a short route with no more than one path
parameter. One column may hold a sentence.

PASS if there are no tables, or every table meets that rule.

FAIL if any table cell holds a JSON or object shape, a list of several status codes with
their meanings, a full route with its base path, or more than one sentence, or if more than
one column holds sentences.
