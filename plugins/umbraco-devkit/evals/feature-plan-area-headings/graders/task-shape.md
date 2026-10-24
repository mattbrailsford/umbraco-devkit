---
type: llm
focus: {source: file, path: docs/plans/subscriptions/PLAN.md}
---
PASS if every task in PLAN.md starts with a bold id (`**T1**`), names the story it
implements, and has its own `Acceptance:` line and its own `depends-on:` line, and the tasks
sit under `##` headings by area of the feature (for example data, Management API,
backoffice).

FAIL if any task lacks an Acceptance or depends-on line, or the tasks are one flat list with
no area headings.
