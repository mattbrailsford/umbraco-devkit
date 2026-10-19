---
description: "pr-describe on a branch stacked on another open PR targets that branch as the base and opens the body noting the stack, instead of targeting main and ignoring the dependency."
tags: [pr-describe, should-trigger]
# covers: ["Workflow"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Write the PR description for my `webhook-retry-backoff` branch. It's built directly on top of
my `webhook-delivery-queue` branch, which already has its own open PR (#142) against `main`
that hasn't merged yet — I branched `webhook-retry-backoff` from it instead of from `main` so I
could keep building without waiting. There's no PR open yet for `webhook-retry-backoff`; get it
ready.

Git and gh can't reach anything here: the branch's diff against `webhook-delivery-queue` is in
`CHANGE.diff` and its commits are in `COMMITS.txt`.
