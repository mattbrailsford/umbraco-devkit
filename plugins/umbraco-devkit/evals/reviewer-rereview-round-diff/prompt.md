---
description: On a re-review round, the reviewer checks the previous findings and the round's own diff, and doesn't fail the task on older code the round didn't touch.
tags: [reviewer, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

This repo is my Umbraco 17 package. Task 2 of the tag-filters plan failed its first review,
and the builder has fixed it. Use the reviewer agent to review it again. Round 1's findings
are in `REVIEW-ROUND-1.md`. Git can't run here, so the whole task's diff is in `CHANGE.diff`
and this round's change is in `ROUND-2.diff`. Tell me PASS or FAIL.
