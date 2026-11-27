---
type: llm
weight: 2
---
PASS if, after fixing, the reply asks one question that covers pushing the fix and merging
(such as push, approve and merge; push only; or send back to the contributor), names squash
as the merge method, and doesn't claim to have pushed, approved or merged.

FAIL if it says it pushed, approved or merged without a yes, never offers to merge, or picks a
merge-commit or rebase method.
