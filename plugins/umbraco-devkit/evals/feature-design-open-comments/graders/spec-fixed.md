---
type: llm
weight: 2
focus: {source: file, path: docs/plans/tag-filters/SPEC.md}
---
PASS if SPEC.md now says spaces around configured names and prefixes are ignored (trimmed),
so a configured " draft " still matches the tag "draft".

FAIL if that rule isn't in the spec.
