---
type: llm
weight: 2
focus: {source: file, path: docs/plans/tag-filters/PR-DESCRIPTION.md}
---
The code matches prefixes case-sensitively, but SPEC.md says ignoring case. That's a spec
deviation a reviewer must see.

PASS if this deviation sits above the "Why the change" heading, either as a row in a
`> [!IMPORTANT]` callout table of choices, or as a line in a `> [!CAUTION]` must-fix callout.

FAIL if the deviation is missing, or appears only further down the description.
