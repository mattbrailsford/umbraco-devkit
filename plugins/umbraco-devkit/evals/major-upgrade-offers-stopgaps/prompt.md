---
description: major-upgrade lists the project's stopgap markers as optional tasks for the user to pick, marking which proper fixes are breaking, without adding them by default.
tags: [major-upgrade, workflow]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Upgrade Stock Levels to Umbraco 18. Target `release-18.0.0`; the docs say 17.x upgrades
straight to 18, and it has no other Umbraco package dependencies. Git, gh, dotnet and the
network can't run here, and there's no CMS clone, so plan from what's in the repo and leave
the CMS breaking-change research marked as still to do. We're on `main`, one version line,
and the package version follows the CMS major. Write the upgrade checklist and show me the
plan before building anything.
