---
description: "pr-demo sets up the content feature-build recorded in BUILD-LOG.md's Demo setup note, not content it invents from the diff."
tags: [pr-demo, workflow]
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill]
---

I want to click through the tag-filters branch myself before I merge it. It's in its own
worktree already. Git and gh can't run in here, so I saved `git worktree list` in
`WORKTREES.txt`; the branch's files are in `worktrees/tag-filters/`. You can't start the site
from here either, so just tell me what you'd set up and what I should click through.
