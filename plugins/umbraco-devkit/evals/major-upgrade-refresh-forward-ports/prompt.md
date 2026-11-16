---
description: "On a refresh, major-upgrade checks that every fix released on the older line since the new line was cut is also on the new line, matching by code, not only by commit message."
tags: [major-upgrade, workflow]
max_turns: 50
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Umbraco 19.0.0-rc1 is out. Refresh our v19 upgrade to it so we can put out our own rc1.
dotnet, npm and the network can't run here. Git works, and the CMS clone in
`CLAUDE.local.md` has the tags. The real `gh` can't reach GitHub, so use `./.tools/gh` in
its place. Update the upgrade checklist and show me the plan before building anything.
