---
description: "pr-describe puts a recorded interaction GIF from screenshots/ under its screen's screenshot, with a caption and a full commit-pinned URL, and keeps the still."
tags: [pr-describe, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Write the PR description for the `gallery-sorting` branch. Git and gh can't reach anything
here: the branch's diff against `main` is in `CHANGE.diff` and its commits are in
`COMMITS.txt`. The branch is pushed to `acme/Umbraco.Community.Gallery` and its head commit
is `9f8e7d6c5b4a39281706f5e4d3c2b1a098765432`. There's no PR yet; just get the description
ready.
