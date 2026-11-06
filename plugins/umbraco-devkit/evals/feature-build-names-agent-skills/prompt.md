---
description: feature-build's builder dispatch names the skills the task needs, and asks the builder to report which skills it loaded.
tags: [feature-build, workflow]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Carry on with the feature-build skill for tag-filters; we're in its worktree. T2 is next.
Git can't run here, and you can't dispatch agents, so write out the exact prompt you'd send
the builder for T2.
