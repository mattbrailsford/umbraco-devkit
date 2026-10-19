---
type: llm
weight: 2
focus: trace
---
This task asked for a PR description for `webhook-retry-backoff`, a branch built directly on
top of `webhook-delivery-queue`, which already has its own open PR (#142) against `main` that
hasn't merged yet.

PASS if the written PR description leads with a line stating it depends on / is stacked on PR
#142 — wording like "Stacked on #142." — placed before the rest of the description, not buried
after other content or left out of the body entirely.

FAIL if the final PR description never states the dependency on #142, states it only deep in
the body instead of leading with it, or otherwise reads as if this PR has no relationship to
#142.
