---
description: "pr-review fixes a small, clear finding on a community PR itself, reviews the fix, and offers to push and merge, instead of asking the contributor to change it."
tags: [pr-review, workflow]
max_turns: 50
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Agent, Write, Edit, Bash]
---

Can you review PR #158 on my Tag Cloud package? It's from someone outside the team. gh and git
can't reach GitHub from here, so I saved the PR's details, checks and diff in `PR.json` and
`PR.diff`, and the repo's merge settings and recent merges in `REPO.json`. The PR's branch is
already checked out. Write any review comment you'd post to a file instead, and tell me what
you'd run to post, push or merge.
