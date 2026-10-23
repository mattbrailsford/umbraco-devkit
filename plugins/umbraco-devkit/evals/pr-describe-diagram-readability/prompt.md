---
description: "pr-describe's change outline marks a changed file without removing and re-adding its line, and shows new routes next to existing ones in a table, never a table inside a diff block."
tags: [pr-describe, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Write the PR description for the `tag-pinning` branch. Git and gh can't reach anything here:
the branch's diff against `main` is in `CHANGE.diff` and its commits are in `COMMITS.txt`.
There's no PR yet; just get the description ready.
