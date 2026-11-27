---
description: pr-describe --start writes a short draft body that links the task list on the branch (not a commit) and opens the PR as a draft with --body-file.
tags: [pr-describe, workflow]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Run the pr-describe skill with `--start` for tag-dashboard. We're on the `tag-dashboard`
branch; the plan folder is committed and the branch is pushed. Git and `gh` can't run here.
Wherever you'd call either, read `TOOL-OUTPUT.txt` instead: it holds what each command would
return. Save the description where the skill says to, and write the exact commands you'd run
into `docs/pr-commands.md`.
