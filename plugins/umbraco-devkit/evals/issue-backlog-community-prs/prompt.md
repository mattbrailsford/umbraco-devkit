---
description: "issue-backlog counts community PRs by review state, leaves out bot and team PRs, and picks the community PR stage before investigation, merge-ready PRs first."
tags: [issue-backlog, workflow]
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Let's work through the backlog. gh can't reach GitHub from here. `ISSUES.json` is a fresh
export of every open issue with its labels, and `PULLS.json` is a fresh export of every open
pull request from `gh api repos/jodean/Umbraco.Community.TagCloud/pulls`, with each PR's
reviews and commits added.
