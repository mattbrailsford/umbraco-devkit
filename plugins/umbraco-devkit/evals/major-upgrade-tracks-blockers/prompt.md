---
description: major-upgrade records each missing Umbraco product dependency as a blocker with the feed it's on and the feed it's needed on, holds back only the projects that need it, and plans its own breaking-change inventory for when it lands.
tags: [major-upgrade, workflow]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Start the Umbraco 19 upgrade for Order Exports, targeting `release-19.0.0-rc1`; the docs say
18.x upgrades straight to 19. Where the other Umbraco products stand today: Umbraco Deploy has
no 19 release anywhere yet, not on NuGet and not on the MyGet pre-release feed. Umbraco
Automate has `19.0.0-rc1`, but only on MyGet so far. Git, gh, dotnet and the network can't
run here, and there's no CMS clone, so plan from what's in the repo and leave the CMS
breaking-change research marked as still to do. We're on `main`, one version line. Write the
upgrade checklist and show me the plan before building anything.
