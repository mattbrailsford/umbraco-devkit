---
description: change-build must hand a change that needs stored data and a new screen to feature-explore, without writing a change file or code.
tags: [change-build, workflow]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Use the change-build skill: editors want to see who last changed My Package settings and
when, with a history list they can open from the settings screen. We're on `main`, the tree
is clean. Git and dotnet can't run here.
