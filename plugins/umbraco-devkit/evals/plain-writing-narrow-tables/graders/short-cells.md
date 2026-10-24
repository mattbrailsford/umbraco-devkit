---
type: llm
weight: 2
focus: {source: file, path: docs/proposals/caching-options.md}
---
Look only at Markdown tables in the file. A cell is short when it holds a few words, a name,
a number, a yes/no or a size. Names of types, packages or settings count as short.

PASS if there are no tables, or every table has four columns or fewer and at most one column
whose cells hold full sentences.

FAIL if any table has five or more columns, or two or more columns whose cells hold full
sentences or several clauses.
