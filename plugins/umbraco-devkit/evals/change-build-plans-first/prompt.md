---
description: change-build must write the change file (problem, cause, approach, task checklist) and wait for a yes before any code changes.
tags: [change-build, workflow]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Use the change-build skill: saving My Package settings with an empty Name gives editors a
500 error and still saves the record. Profiles do the same. Make both return a 400 with the
field errors instead. We're on `main`, the tree is clean. Git and dotnet can't run here.
