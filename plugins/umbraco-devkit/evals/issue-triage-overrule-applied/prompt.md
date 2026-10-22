---
description: "issue-triage --via-tracker acts on a maintainer overruling an applied outcome: closes it as a duplicate, replies with the link, and settles the record, keeping it marked as applied."
tags: [issue-triage, workflow]
max_turns: 20
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Run /issue-triage 140 --unattended --via-tracker.

gh can't reach GitHub from here; `ISSUE-140.md` has the issue and its comments, and `ACCESS.md` lists who has write access. Instead of each tracker write, append it to `TRACKER-WRITES.md`: what it is (new comment, edit comment, add label, remove label, close) and its full text. `ISSUE-12.md` has issue #12.
