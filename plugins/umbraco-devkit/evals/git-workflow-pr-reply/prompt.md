---
description: "git-workflow replies to each PR review comment through the comments collection with in_reply_to (not the non-existent replies endpoint) and resolves threads over GraphQL by thread id."
tags: [git-workflow, should-trigger]
# covers: ["Pull requests — `gh pr create`"]
max_turns: 20
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Copilot left three review comments on my PR #58. I've already pushed fixes for the first two;
the third doesn't apply and I want to explain why instead. Reply to each comment and resolve
all three threads, since each one now has an answer.

`gh` can't reach anything here: the comments, their ids, thread ids, and current status are in
`COMMENTS.txt`. Write the exact `gh` commands you'd run, with the actual reply text filled in,
into `docs/pr-reply-plan.md`.
