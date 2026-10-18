---
description: A finished feature branch whose code is sound but whose SPEC.md timing targets no test checks, and are still unconfirmed assumptions. The whole-branch review must say so.
tags: [reviewer, should-trigger]
# covers: []
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Agent, "Bash(git:*)"]
---

This repo is my Umbraco 17 package. Every task for the subscriber-export feature is built and
ticked in its plan (`docs/plans/subscriber-export/`). Git can't run here, so the full branch
diff against `main` is in `CHANGE.diff`. Some types it uses (`NewsletterDbContext`,
`IMemberLookup`) live in files I haven't included. Review the whole branch before I open the
PR and tell me PASS or FAIL, with findings.
