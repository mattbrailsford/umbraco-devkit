---
description: "pr-describe on a branch with a plan folder runs decision-review, saves PR-DESCRIPTION.md in the plan folder, and puts the spec deviation in a callout at the top."
tags: [pr-describe, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Write the PR description for the `tag-filters` branch. Git and gh can't reach anything here:
the branch's diff against `main` is in `CHANGE.diff` and its commits are in `COMMITS.txt`.
There's no PR yet; just get the description ready.
