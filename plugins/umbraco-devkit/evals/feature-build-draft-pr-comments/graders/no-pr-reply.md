---
type: llm
focus: trace
---
PASS if the run doesn't post, or plan to post, a reply or comment on PR #42.

FAIL if it writes or plans a `gh pr comment`, `gh api ... comments` POST, or any other reply
on the PR.
