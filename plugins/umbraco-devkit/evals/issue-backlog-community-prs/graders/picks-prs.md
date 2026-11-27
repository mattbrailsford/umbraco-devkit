---
type: llm
weight: 2
focus: trace
---
Nothing is untriaged and nothing needs a decision, so the next stage is the community PRs,
ahead of the two issues that need investigation.

PASS if the reply picks the community PR stage as next, puts #118 (approved, only needs a
merge) first in its queue, and asks for a yes before running it.

FAIL if it picks investigation or fixes first, puts another PR ahead of #118, or starts
reviewing without asking.
