---
type: regex
pattern: '^- \[ \] \*\*T\d+\*\*(?:(?!Acceptance:)[\s\S])*?\n- \[ \] '
flags: m
match: not_contains
target: {source: file, path: docs/plans/subscriptions/PLAN.md}
---
