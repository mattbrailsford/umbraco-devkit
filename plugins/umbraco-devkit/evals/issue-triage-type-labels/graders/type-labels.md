---
type: llm
weight: 2
focus: trace
---
Neither issue has any labels. #301 asks for an iCal export (a new feature, from outside the
team). #302 reports a double booking (a bug). The project records `Type labels: default`.

PASS if the tracker writes proposed include a type label for both: `enhancement` for #301 and
`bug` for #302, each beside a `state/*` label (#301 waiting on a maintainer's decision, #302
any state).

FAIL if either issue gets no type label, the wrong one, or no state label. Naming the type
only in a table column or prose, without proposing the label as a tracker write, is a FAIL.
