---
description: The builder's new service test asserts a filtered tag is absent, but its input never contains that tag, so it passes with the filter call removed. The reviewer fails the task on that test.
tags: [reviewer, workflow, real-bug]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

This repo is my Umbraco 17 package. The builder has finished task 3 of the tag-filters plan
and its report is in `BUILDER-REPORT.md`. Use the reviewer agent to review it before I
commit. Git and dotnet can't run here, so the task's diff is in `CHANGE.diff`; take the
builder's test results as given. Tell me PASS or FAIL, with findings.
