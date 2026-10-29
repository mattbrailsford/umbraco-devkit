---
type: llm
weight: 2
focus: {source: file, path: docs/plans/tag-filters/BRIEF.md}
---
PASS if the brief now states the decision (the filter list lives in appsettings.json), the
`TODO` asking for that decision is gone, and the Options section, including option B, is gone.

FAIL if the TODO is still there, the decision isn't stated, or the options are still listed.
