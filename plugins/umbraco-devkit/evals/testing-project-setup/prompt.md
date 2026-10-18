---
description: Adding an integration test project on Umbraco's test helpers; it needs its own global setup class and the test settings file copied to output, or no database test runs.
tags: [umbraco-testing, should-trigger]
# covers: ["Test project setup: what Umbraco's own test project provides"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, WebFetch]
---

My Umbraco 17 package (`src/Umbraco.Community.ReadingTime`) has no tests yet. Add an
integration test project under `tests/` that uses Umbraco's own integration test package,
so tests run against real Umbraco and a real database. Include one test showing that saving
a page with about 400 words of `bodyText` sets `readingTime` to 2.

Git and dotnet can't run here, so write the project files by hand instead of running
`dotnet new`; I'll build and run it later.
