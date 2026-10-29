---
description: "issue-triage --via-tracker applies an outcome on the Auto-apply line straight away: a record marked as applied, the reply, and the label, with no state/drafted."
tags: [issue-triage, workflow]
max_turns: 20
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Run /issue-triage 102 --unattended --via-tracker.

gh can't reach GitHub from here; `ISSUE-102.md` has the issue and its comments, and `ACCESS.md` lists who has write access. Instead of each tracker write, append it to `TRACKER-WRITES.md`: what it is (new comment, edit comment, add label, remove label, close) and its full text.
