---
description: On a clean diff in a file with an older bug, the reviewer lists the older bug as Pre-existing and doesn't fail the change for it.
tags: [reviewer, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

This repo is my Umbraco 17 package. The task was "add `TagRanking.GetTop(tags, count)` for the
dashboard's top-tags list, with unit tests". It's the uncommitted change in the working tree.
Use the reviewer agent on it before I commit. Git can't run here, so the diff is in
`CHANGE.diff`.
