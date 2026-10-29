---
description: major-upgrade finds an unlabelled signature change in a CMS base class the package overrides by diffing the types the package uses between the two tags.
tags: [major-upgrade, workflow]
max_turns: 50
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Upgrade Price Badge to Umbraco 18, targeting `release-18.0.0`. The docs say 17.x upgrades
straight to 18, and it has no other Umbraco package dependencies. dotnet, npm and the
network can't run here. Git works, and the CMS clone in `CLAUDE.local.md` has both tags. The
real `gh` can't reach GitHub, so use `./.tools/gh` in its place: it answers from a recorded
copy of the Umbraco-CMS PRs and releases.
We're on `main`, one version line, and the package version follows the CMS major. Write the
upgrade checklist and show me the plan before building anything.
