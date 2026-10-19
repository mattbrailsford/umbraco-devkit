---
description: "issue-resolve routes to pr-review instead of a fix lane when the ready issue already has an open PR from an outside contributor."
tags: [issue-resolve, workflow]
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Use the issue-resolve skill to fix #58. gh can't reach GitHub from here, so the issue and this
morning's triage report are in `ISSUE-58.md`.
