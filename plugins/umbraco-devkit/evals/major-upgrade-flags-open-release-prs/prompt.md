---
description: Against a CMS release candidate, major-upgrade lists the open CMS PRs still labelled for the release that would hit the package, and keeps them out of the tasks.
tags: [major-upgrade, workflow]
max_turns: 50
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

The CMS team has put out the first Umbraco 19 RC, and we want a Stock Levels pre-release
ready against it. Upgrade Stock Levels to Umbraco 19. It has no other Umbraco package
dependencies, and 18.4 upgrades straight to 19. dotnet, npm and the network can't run here.
Git works, and the CMS clone in `CLAUDE.local.md` has the tags. The real `gh` can't reach
GitHub, so use `./.tools/gh` in its place. We're on `main`, one version line, and the
package version follows the CMS major. Write the upgrade checklist and show me the plan
before building anything.
