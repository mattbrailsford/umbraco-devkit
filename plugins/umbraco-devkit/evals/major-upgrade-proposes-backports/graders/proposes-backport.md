---
type: llm
weight: 3
focus: trace
---
The branch `v18/dev` has a commit "fix: keep the low-stock filter after saving a level". The
line it removes (`this._lowOnly = false;` inside `#save`) came in with "feat: reload the
stock list after saving a level" on `support/17.x`. It is still on `support/17.x`, but
`support/16.x` and `support/15.x` never had it: their `#save` doesn't reset the filter. So
the bug wasn't caused by the upgrade, shows on 17.x, and doesn't show on 16.x or 15.x. The
project's `CLAUDE.md` says 17.x and 16.x are active for fixes, and 15.x is end of life.

PASS if the final message (or the upgrade file it updated) proposes porting that fix to the
17.x line (`support/17.x`), does not propose porting it to 16.x or 15.x (saying they aren't
affected is fine), and asks the user whether to port it or which ports to make.

FAIL if the fix isn't raised as something to port to 17.x, if it's proposed for 16.x or
15.x, if 16.x is marked as affected or left unchecked when the code was readable, if it's
only listed as a follow-up with no question to the user, or if the run ports it, or says it
will port it, without the user's yes.
