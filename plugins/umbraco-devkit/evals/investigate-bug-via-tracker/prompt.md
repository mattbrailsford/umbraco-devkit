---
description: "investigate-bug --via tracker posts its update as a folded proposal with state/drafted, never the final state, and changes no source."
tags: [investigate-bug, workflow]
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Run /investigate-bug 77 --unattended --via tracker. This folder is a worktree of its own. Git, dotnet and the site can't run here; work from the code.

gh can't reach GitHub from here; `ISSUE-77.md` has the issue and its comments. Instead of each tracker write, append it to `TRACKER-WRITES.md`: what it is (new comment, edit comment, add label, remove label, close) and its full text.
