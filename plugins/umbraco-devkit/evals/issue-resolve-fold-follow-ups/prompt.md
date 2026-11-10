---
description: "issue-resolve folds follow-ups with the fix's own cause into the same PR, asks the maintainer for an open decision instead of splitting it off, and splits only what must ship separately, naming why."
tags: [issue-resolve, workflow]
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

I maintain this package. Use the issue-resolve skill on #64. The quick-fix for it is committed on
`fix/64-save-permission` and PR #66 is open. Close the loop: the issue, this morning's triage
report, the fix's hand-off and the reviewer's notes are all in `FIX-64.md`. Git and gh can't
run here.
