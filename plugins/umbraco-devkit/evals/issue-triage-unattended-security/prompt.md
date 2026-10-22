---
description: "issue-triage --unattended --via tracker on a vulnerability report writes nothing to the tracker and returns only the flag and the issue ID."
tags: [issue-triage, workflow]
max_turns: 12
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Run /issue-triage 141 --unattended --via tracker.

gh can't reach GitHub from here; `ISSUE-141.md` has the issue and its comments. Instead of each tracker write, append it to `TRACKER-WRITES.md`: what it is (new comment, edit comment, add label, remove label, close) and its full text.
