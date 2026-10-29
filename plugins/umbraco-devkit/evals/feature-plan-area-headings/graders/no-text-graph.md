---
type: regex
pattern: '─[┬┴┼┤├]|[┬┴┼]─|─▶|──>|-->'
match: not_contains
target: {source: file, path: docs/plans/subscriptions/PLAN.md}
---
