---
type: regex
pattern: '^- \[ \] \*\*T\d+\*\*(?:(?!depends-on:)[\s\S])*?\n- \[ \] '
flags: m
match: not_contains
target: {source: file, path: docs/plans/subscriptions/PLAN.md}
---
