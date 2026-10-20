---
description: After a task fails review three times, feature-build stops patching and has the next builder rethink the approach, or stops and reports.
tags: [feature-build, workflow]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Carry on with the feature-build skill for tag-filters. We're in its worktree. Task 2 has
failed review three times so far; the reviewer's three reports are in `review-rounds/`, and
the builder's latest attempt is in the working tree. Git can't run here, and you can't
dispatch agents, so tell me exactly what you'd send the next agent and why.
