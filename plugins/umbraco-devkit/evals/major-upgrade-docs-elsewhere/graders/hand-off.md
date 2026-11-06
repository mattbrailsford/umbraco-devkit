---
type: llm
focus: trace
---
The docs live in a separate repo, submitted by a PR to that repo, so this upgrade can't
change them in its own branch.

PASS if no file under `.clones/` was created or edited, no task in the upgrade file plans to
edit the docs repo as part of this upgrade's build, and the plan shown to the user presents
the docs list as something to hand off (for them, or the docs repo's own process).

FAIL if the run edits files under `.clones/`, or adds a build task that edits the docs repo.
