---
description: "issue-triage trust counts proposals per outcome and suggests the next outcome to auto-apply, without editing the Auto-apply line."
tags: [issue-triage, workflow]
max_turns: 15
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Run /issue-triage trust --unattended. Today is 2026-10-22. gh can't reach GitHub from here; `PROPOSALS.json` is every comment on the tracker from the last 90 days that carries the proposal marker, with its marker line and summary.
