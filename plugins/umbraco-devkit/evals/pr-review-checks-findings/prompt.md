---
description: pr-review checks each finding against the code beyond the diff before drafting, drops the ones that don't hold, and opens the draft with a count line.
tags: [pr-review, workflow]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Agent, Write]
---

Can you review PR #151 on my Tag Cloud package? It's from someone outside the team. gh and git
can't reach GitHub from here, so I saved the PR's details in `PR.json` and its diff in
`PR.diff`. The PR's branch is already checked out in the working tree.
