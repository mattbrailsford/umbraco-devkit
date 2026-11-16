---
description: At Finish, major-upgrade sends the docs screenshots the screen comparison says to retake to a smoke-tester, with each image's path and click path, and never opens the images itself.
tags: [major-upgrade, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill]
---

Carry on with the v18 upgrade of Stock Levels from `docs/upgrades/v18.md`; the smoke-testers
have compared every screen and their results are in its table. Git can't run here, and you
can't run commands, dispatch agents or drive a browser, so write out exactly what you'd do
next for the screenshots, and the exact prompt for any agent you'd send. Stop before the
whole-branch review.
