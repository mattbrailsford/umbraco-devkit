---
type: llm
focus: trace
---
PASS if the README.md written in this run indexes the plan files as a table with one row per
file (Brief, Architecture, Spec, Stories, Plan), a short "in one line" column and a
"needs you" column, with only the Brief row filled in. The build and decision logs are linked
below the table, not as rows.

FAIL if it's a numbered or bulleted list, or rows other than Brief are filled in.
