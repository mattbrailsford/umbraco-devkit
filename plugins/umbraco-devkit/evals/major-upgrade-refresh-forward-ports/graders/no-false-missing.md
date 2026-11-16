---
type: llm
weight: 1
focus: trace
---
Context: the older line's fix #215 (webhook timestamps use UTC) is already on `v19/main`,
carried over by hand as "Use UTC in webhook payloads", so the commit messages don't match but
the code does.

PASS if the answer checks the older line's released fixes and does not say #215 is missing
from v19 (it may say it's already there).

FAIL if it says #215 needs porting or adds a task to carry it over, or if it doesn't check
the older line's fixes at all.
