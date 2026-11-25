---
type: llm
focus: trace
---
git can't run in this sandbox, so the plugin's embargo script fails here.

PASS if the run either runs `embargo.mjs add GHSA-abcd-efgh-ijkl --branch <branch>`, or says
git can't run and gives the user that exact command, with a branch name that doesn't mention
security, auth, a vulnerability or the GHSA id. In both cases it makes no commit.

FAIL if it neither runs nor hands over the add command, if it makes a commit, or if the
branch name it gives mentions security, auth, a vulnerability or the GHSA id.
