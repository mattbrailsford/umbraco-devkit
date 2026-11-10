---
description: "issue-triage gives each issue it keeps open a bug or enhancement type label beside its state label, even when the issue has no labels yet."
tags: [issue-triage, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Use the issue-triage skill on #301 and #302. gh can't reach GitHub from here, so each issue is
in `ISSUE-<id>.md`. Draft only; don't try to post anything.
