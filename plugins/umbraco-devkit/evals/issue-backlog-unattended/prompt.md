---
description: "issue-backlog --unattended --via tracker runs triage as proposals without asking, and skips decisions and fixes."
tags: [issue-backlog, workflow]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Run /issue-backlog --unattended --via tracker. gh can't reach GitHub from here; `ISSUES.json` is a fresh export of every open issue, with its labels, body and comments. Instead of each tracker write, append it to `TRACKER-WRITES.md`. Agents can't run here, so do any investigation in this session.
