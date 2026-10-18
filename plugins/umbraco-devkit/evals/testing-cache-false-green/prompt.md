---
description: Testing that a saved rule shows straight away; the test host disables caching and cache refreshers, so the obvious test passes without them.
tags: [umbraco-testing, should-trigger]
# covers: ["Cache tests: switch caching and refreshers back on"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, WebFetch]
---

My Umbraco 17 package (`src/Umbraco.Community.Redirects`) lets editors manage redirect
rules, which the site reads on every request. Some customer sites are load balanced.

Add integration tests to `tests/Umbraco.Community.Redirects.Tests.Integration` covering
what editors rely on: once the site has served the rules, a rule they save or delete shows
up in `GetAllAsync` straight away.

Git and dotnet can't run here, so you can't build or run the tests; just write them.
