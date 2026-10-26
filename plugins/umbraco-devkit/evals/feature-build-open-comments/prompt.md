---
description: Before committing the plan folder and building, feature-build checks the plan for unresolved review comments and raises one still waiting on the user in the same question as the trunk commit.
tags: [feature-build, workflow]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Use the feature-build skill for the tag-filters feature. Git can't run here; we're on `main`
and the plan folder isn't committed yet.
