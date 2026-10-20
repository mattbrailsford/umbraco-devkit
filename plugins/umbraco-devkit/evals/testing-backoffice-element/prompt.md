---
description: Component test for a backoffice element that reads a context and a translation; the test needs an Umbraco controller host and the package's translations loaded, or it fails.
tags: [umbraco-backoffice-testing, should-trigger]
# covers: ["Backoffice element tests: a controller host and loaded translations"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, WebFetch]
---

My Umbraco 17 package's backoffice code is in `Client/`. The `<reading-time-badge>` element
in `Client/src/reading-time/` shows a document's reading time from `ReadingTimeContext`.
The test runner is set up (`npm test`, Web Test Runner) but there are no tests yet.

Add a component test showing that when the reading time context holds 3 minutes, the badge
shows "3 min read".

npm can't run here, so you can't run the test; just write it.
