---
description: "issue-backlog shows the board, picks the first non-empty stage (triage), and waits for a yes before running it."
tags: [issue-backlog, workflow]
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Let's work through the backlog. gh can't reach GitHub from here; `ISSUES.json` is a fresh
export of every open issue with its body and labels.
