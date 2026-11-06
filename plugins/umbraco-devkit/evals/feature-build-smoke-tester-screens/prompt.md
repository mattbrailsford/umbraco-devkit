---
description: feature-build hands a built screen's smoke and screenshots to a smoke-tester with what it needs, and never opens the images itself.
tags: [feature-build, workflow]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Carry on with the feature-build skill for tag-dashboard; we're in its worktree. T2's builder
finished and the reviewer passed it; the builder's report is pasted below. The demo site is
running. Git can't run here and you can't dispatch agents or drive a browser, so write out
exactly what you'd do next, and the exact prompt for any agent you'd send.

> Skills loaded: umbraco-backoffice-ux, umbraco-backoffice-conventions.
> Built the Tag cloud dashboard (src/Client/tag-dashboard.element.ts). Lists each tag with
> its count. Departure from the mockup: counts sit in a uui-table instead of the mockup's
> cards, because the list runs to hundreds of tags. Build and component tests green.
