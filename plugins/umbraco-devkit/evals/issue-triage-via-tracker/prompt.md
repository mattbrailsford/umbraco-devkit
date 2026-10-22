---
description: "issue-triage --unattended --via tracker posts one folded proposal and state/drafted, asks nothing, and sets no final state or reporter reply."
tags: [issue-triage, workflow]
max_turns: 20
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Run /issue-triage 140 --unattended --via tracker.

gh can't reach GitHub from here; `ISSUE-140.md` has the issue and its comments. Instead of each tracker write, append it to `TRACKER-WRITES.md`: what it is (new comment, edit comment, add label, remove label, close) and its full text.
