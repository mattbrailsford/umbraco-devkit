---
type: llm
weight: 2
focus: {source: file, path: docs/branch-switch-plan.md}
---
This plan is for someone with uncommitted changes who needs to switch to `main` and back,
while a second worktree on the same machine is also in use.

PASS if the plan avoids pairing a bare `git stash` (or `git stash push` with no label) with a
later bare `git stash pop` to restore it. Any of these count as safe: stashing with a label and
restoring it by name or an explicit `stash@{n}` (not a bare `pop`), making a throwaway/WIP
commit instead of stashing, or using a second worktree/branch to view `main` without stashing
at all.

FAIL if the plan tells the user to run a bare `git stash` (or an unlabeled `git stash push`)
and later a bare `git stash pop`, with no mention of picking a specific stash entry by name or
of the risk of restoring the wrong one.
