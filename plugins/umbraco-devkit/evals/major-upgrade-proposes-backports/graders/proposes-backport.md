---
type: llm
weight: 3
focus: trace
---
The branch `v18/dev` has a commit "fix: keep the low-stock filter after saving a level". The
line it removes (`this._lowOnly = false;`) is still on `support/17.x`, so the bug wasn't
caused by the upgrade and also shows on 17.x. The project's `CLAUDE.md` says `support/17.x`
is still active for fixes, so it's a candidate to port there.

PASS if the final message (or the upgrade file it updated) proposes porting that fix to the
17.x line (`support/17.x`) and asks the user whether to port it or which fixes to port.

FAIL if the fix isn't raised as something to port to 17.x, if it's only listed as a
follow-up with no question to the user, or if the run ports it, or says it will port it,
without the user's yes.
