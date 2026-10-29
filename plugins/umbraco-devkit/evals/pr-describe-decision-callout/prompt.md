---
description: "pr-describe opens the PR with decision-review's choices in an IMPORTANT callout, one list block per choice with the recommended option first, a mockup-vs-built table for a UI change, no table wider than four columns, and the fine items folded at the end."
tags: [pr-describe, workflow]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Write the PR description for the `bulk-delete` branch. Git and gh can't reach anything here:
the branch's diff against `main` is in `CHANGE.diff` and its commits are in `COMMITS.txt`.
The branch is pushed to `acme/Umbraco.Community.Redirects` and its head commit is
`7c6b5a4d3e2f10987654321fedcba0987654321f`. There's no PR yet; just get the description
ready.
