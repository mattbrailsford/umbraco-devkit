---
type: llm
weight: 2
focus: {source: file, path: docs/plans/scheduled-unpublish/SPEC.md}
---
Look at the "Settings" section.

PASS if it shows the three settings as an `appsettings.json` block (a `json` or `jsonc` code
block nested under Umbraco > MyPackage > ScheduledUnpublish), with each default value and a
short comment per setting giving its meaning and the 1-60 range where it applies.

FAIL if the settings are only a table or a list, the block is missing a setting or a
default, or it's flat colon-separated keys instead of nested JSON.
