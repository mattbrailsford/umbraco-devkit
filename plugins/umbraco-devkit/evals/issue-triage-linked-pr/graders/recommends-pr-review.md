---
type: llm
weight: 2
focus: trace
---
#84 already has an open PR (#87) from an outside contributor.

PASS if the recommended action for #84 names `pr-review` explicitly together with PR #87,
rather than a state label meant for building a fix (`state/ready`, `state/needs-investigation`,
etc.) or a generic line like "review the PR(s)" that doesn't name the skill.

FAIL if the recommendation only applies a triage state label with no mention of `pr-review`,
or mentions reviewing the PR without naming `pr-review` by name.
