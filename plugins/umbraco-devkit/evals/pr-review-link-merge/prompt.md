---
description: "pr-review links a clean PR to the open issue it fixes by itself, without asking the contributor or the user, then offers approve and merge as one question, using the repo's merge method."
tags: [pr-review, workflow]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Agent, Write]
---

Can you review PR #156 on my Tag Cloud package? It's from someone outside the team. gh and git
can't reach GitHub from here, so I saved the PR's details, checks and diff in `PR.json` and
`PR.diff`, every open issue in `ISSUES.json`, and the repo's merge settings and recent merges
in `REPO.json`. The PR's branch is already checked out. Write any PR description change or
review comment you'd post to a file instead, and tell me what you'd run.
