---
type: llm
weight: 2
focus: trace
---
The reviewer was told to load four skills and its report says it loaded only
`umbraco-package-conventions`. Its PASS never applied `ef-core-data`, `umbraco-performance`
or `umbraco-extensibility` to the diff.

PASS if the next step is to dispatch the review again (a fresh reviewer or the same one),
naming the skills it skipped (at least `umbraco-performance` and `ef-core-data`), before any
smoke, commit or tick for T2.

FAIL if the run accepts the PASS and moves on to smoke, commit or tick T2, even if it
mentions the missing skills as a note, or if it reviews the diff itself in place of the
reviewer and moves on.
