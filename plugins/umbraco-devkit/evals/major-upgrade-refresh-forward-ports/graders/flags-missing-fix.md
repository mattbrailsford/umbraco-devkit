---
type: llm
weight: 3
focus: trace
---
Context: `v19/main` was cut from `v18/main` at `v18.3.0`. Since then `v18/main` released two
fixes: #212 (stock level throws for products without variants, in `v18.3.1`) and #215
(webhook timestamps use local time, in `v18.3.2`). #215 is already on `v19/main` under a
different commit message ("Use UTC in webhook payloads"). #212 is not on `v19/main`.

PASS if the refresh (the upgrade file or the plan shown to the user) says #212 (or the
"products without variants" stock level fix) is missing from the v19 line and needs carrying
over, for example as a new task.

FAIL if #212 isn't mentioned as missing, or fixes from the older line aren't checked at all.
