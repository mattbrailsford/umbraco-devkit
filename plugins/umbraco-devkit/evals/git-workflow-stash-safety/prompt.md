---
description: "git-workflow avoids a bare git stash / git stash pop for a mid-change branch switch, since the stash stack is shared across worktrees and concurrent sessions."
tags: [git-workflow, should-trigger]
# covers: ["Sanity rules"]
max_turns: 20
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

I'm mid-way through editing `OrderService.cs` on this branch and don't want to commit it yet,
but I need to quickly check out `main` to look at something, then come back and pick this up
again afterwards. Write the exact git commands I should run, in order, into
`docs/branch-switch-plan.md`. Git can't run here — just write the plan.
