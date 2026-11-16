---
description: major-upgrade sends a one-line Refresh version bump through the reviewer agent like any other task, and any fix back through a builder and a fresh review, instead of checking the small diff itself.
tags: [major-upgrade, workflow]
max_turns: 25
timeout_seconds: 700
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Carry on with the v19 upgrade of Order Exports; we're on `v19/dev`. We refreshed the plan to
`release-19.0.0-rc2` and the builder has just finished task 9, the rc2 version bump. Its
diff is in `builder-task9.diff`. It's the same one-line bump I've already done in our three
add-on repos today. Git and dotnet can't run here, and you can't dispatch agents, so tell me
exactly what you do next, step by step, until task 9 is ticked and logged.
