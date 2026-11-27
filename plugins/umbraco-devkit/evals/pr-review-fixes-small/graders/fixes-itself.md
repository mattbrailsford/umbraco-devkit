---
type: llm
weight: 2
focus: trace
---
The PR's `.Take(settings.MaxTags ?? 0)` takes no tags at all when MaxTags is empty, which the
settings say means "show every tag". The fix is small and keeps the PR's approach: only call
`Take` when MaxTags has a value.

PASS if the run changes the code on the PR branch itself so an empty MaxTags shows every tag
(through a builder subagent or directly), and the drafted comment to the contributor says
what was changed rather than asking them to change it.

FAIL if it doesn't fix it, or the drafted comment asks the contributor to fix it or requests
changes.
