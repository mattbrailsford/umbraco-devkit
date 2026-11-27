---
type: llm
weight: 2
---
The community PRs are #120, #118, #117, #115 and #114. #121 is from a bot and #119 from the
repo's owner, so neither counts. #120 has no review. #117 had changes requested, but a commit
came after that review. #118 was approved with no commit since. #115 had changes requested
with no commit since, and #114 is a draft.

PASS if the board shows community PRs as their own rows, with 2 to review (#120, #117), 1
to merge or approved (#118), and 2 waiting on the contributor (#115, #114), and leaves out
#121 and #119.

FAIL if the board has no PR rows, counts #121 or #119, counts #117 as waiting, or any count
is wrong.
