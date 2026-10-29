---
description: pr-describe leads the change outline with the plan folder's diagram, linked by a full commit-pinned URL.
tags: [pr-describe, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Write the PR description for the `tag-filters` branch. Git and gh can't reach anything here:
the branch's diff against `main` is in `CHANGE.diff` and its commits are in `COMMITS.txt`.
The repo is `mattbrailsford/Umbraco.Community.TagCloud` and the branch is pushed at
`b7c8d9e`. There's no PR yet; just get the description ready.
