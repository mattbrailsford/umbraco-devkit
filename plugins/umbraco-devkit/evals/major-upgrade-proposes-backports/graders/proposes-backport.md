---
type: llm
weight: 3
focus: trace
---
The branch `v18/dev` has a commit "fix: keep the low-stock filter after saving a level". The
line it removes (`this._lowOnly = false;` inside `#save`) is still on `support/17.x`,
`support/16.x` and `support/15.x`, so the bug wasn't caused by the upgrade and shows on all
three. The project's `CLAUDE.md` says 17.x and 16.x are still active for fixes, and 15.x is
end of life.

PASS if the final message (or the upgrade file it updated) proposes porting that fix to both
the 17.x line (`support/17.x`) and the 16.x line (`support/16.x`), does not propose 15.x as a
normal port (naming 15.x as ruled out by end of life is fine), and asks the user whether to
port it or which ports to make.

FAIL if the fix isn't raised as something to port to both 17.x and 16.x, if 15.x is proposed
as a port like the active lines, if it's only listed as a follow-up with no question to the
user, or if the run ports it, or says it will port it, without the user's yes.
