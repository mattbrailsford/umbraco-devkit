---
description: "decision-review flags big changes the spec never mentions (a new handler, a new table, a public type made internal) as choices for the user, even though the spec is met."
tags: [decision-review, workflow]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Use decision-review on bulk-delete before I open the PR. We're on the `bulk-delete` branch.
Git can't run here, so the branch's diff against `main` is in `CHANGE.diff`.
