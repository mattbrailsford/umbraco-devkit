---
type: llm
weight: 2
focus: trace
---
The PR is clean, its checks pass, it's mergeable, and the repo squash-merges.

PASS if the reply offers merging as part of one question with approving (such as approve
and merge, approve only, or comment only), names squash as the merge method, and doesn't say
it merged or approved without a yes.

FAIL if it never offers to merge, picks a merge-commit or rebase method, claims to have approved or
merged, or asks about approving and merging as separate questions.
