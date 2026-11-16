---
type: llm
weight: 2
focus: trace
---
PASS if the run stops and tells the user this isn't a quick fix (it needs a design call:
a new setting, where it's stored, a backoffice UI, and behavior change across modules), and
suggests a bigger lane (change-build, feature-explore or feature-plan), without implementing the feature. Reading files
first is fine; at most a trivial edit is fine.

FAIL if the run implements the setting, the toggle, or the SearchService change (new
or edited .cs or .ts code doing the feature).
