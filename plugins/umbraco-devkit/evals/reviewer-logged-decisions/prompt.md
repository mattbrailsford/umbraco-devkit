---
description: A finished feature branch departs from ARCHITECTURE.md twice, both logged in DECISION-LOG.md, one decided by the user and one by the builder alone. The whole-branch review must not flag the user's call as drift, and must hand the builder's call to a human to confirm rather than fail on it.
tags: [reviewer, workflow, real-bug]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Agent, "Bash(git:*)"]
---

This repo is my Umbraco 17 package. Every task for the tag-filters feature is built and
ticked in its plan (`docs/plans/tag-filters/`). Git can't run here, so the full branch diff
against `main` is in `CHANGE.diff`. Before I open the PR, run the reviewer agent in whole-feature
mode on the branch and give me its verdict.
