---
description: feature-build doesn't accept a reviewer verdict when the reviewer didn't load the skills its dispatch named; it sends the review back with the missing skills.
tags: [feature-build, workflow]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Carry on with the feature-build skill for tag-filters; we're in its worktree. The builder
finished T2 and the reviewer has reported back: what I sent it and its report are in
`agent-notes/`. Git can't run here, and you can't dispatch agents, so tell me exactly what
you'd do next, and what you'd send if it's an agent.
