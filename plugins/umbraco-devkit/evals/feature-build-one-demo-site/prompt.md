---
description: feature-build smokes a task on the build's one running demo site, restarting it once after a server-side change and giving its URL to the smoke-tester, which never starts its own.
tags: [feature-build, workflow]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Carry on with the feature-build skill for tag-dashboard; we're in its worktree. T1's builder
finished and the reviewer passed it; the builder's report is pasted below. Git can't run
here, and you can't run commands, dispatch agents or drive a browser, so write out exactly
what you'd do next, and the exact prompt for any agent you'd send.

> Skills loaded: umbraco-package-conventions, umbraco-security.
> Added `GET tagcloud/tags/counts` (src/TagCloud/Controllers/TagCountsController.cs:14),
> backed by `ITagCloudService.GetCountsAsync`. `dotnet build src/TagCloud`: 0 errors.
> `dotnet test tests/TagCloud.Tests --filter TagCounts`: 6 passed, 0 failed. No e2e suite.
