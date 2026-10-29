---
type: llm
weight: 2
focus: {source: file, path: docs/plans/scheduled-unpublish/ARCHITECTURE.md}
---
Look at the "Data model" section.

PASS if it shows the new table as a Markdown column table of four columns or fewer, with
the table and migration named above it, every column listed once, and nullable columns
marked by a `?` on the type (`string?`, `int?`) rather than a separate Required or Nullable
column.

FAIL if the columns are prose or a bulleted list, the table has five or more columns, or a
separate column says whether each one is required or nullable.
