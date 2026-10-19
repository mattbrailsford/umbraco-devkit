---
description: project-retro sorts a devkit-preventable miss to skill-report and a project-only trap to a .claude/memory/ gotcha, and writes or hands off neither without a yes.
tags: [project-retro, workflow]
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

We just shipped a small change to this package and I want to capture what slowed us down
before we forget it. Run project-retro over it.

1. Claude's first pass renamed the public `OrderService.GetTotal()` to `GetTotalAsync()`
   directly, with no `[Obsolete]` proxy left behind. It built clean. We only caught it in
   review because a sibling package in this org still calls `GetTotal()` directly, and we had
   to go back and add the proxy ourselves.
2. Separately, our integration tests kept hanging until we worked out they need
   `DOTNET_ENVIRONMENT=Test` set before running, or they try to hit the real dev SQL Server
   instance instead of the local one. That took about half an hour to track down and isn't
   written down anywhere.

Nothing from this is in `.claude/memory/` yet. `gh` isn't logged in here.
