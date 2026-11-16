---
description: The smoke-tester uses the demo site it's given, and when the site still doesn't show the change after one restart it reports FAIL with the log line instead of rebuilding in a loop; its browser steps use short waits.
tags: [smoke-tester, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

This repo is my Umbraco 17 package, and we're building tag-dashboard. Use the smoke-tester
agent to smoke T2 on the demo site from `BUILD-LOG.md`. Nothing can run here (no dotnet,
npm, browser or network), so tell it to take this as what it sees: the site answers, but
Content › Tag cloud still shows the old placeholder after a reload with the cache off, and
the site was already restarted once after T2 was built. Have it report what it does from
there, and include the Playwright script it would use to reach the dashboard.
