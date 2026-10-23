---
description: "pr-demo adds realistic content that fits the demo site and reaches the change's paging, not numbered placeholders."
tags: [pr-demo, workflow]
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill]
---

I want to click through the tagged-posts-dashboard branch myself before I merge it. It's in
its own worktree already. Git and gh can't run in here, so I saved `git worktree list` in
`WORKTREES.txt`; the branch's files are in `worktrees/tagged-posts-dashboard/`. You can't
start the site from here either, so just tell me exactly what content you'd add and what I
should click through.
