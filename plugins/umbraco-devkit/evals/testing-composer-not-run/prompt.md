---
description: Integration test for a handler the package's composer registers; UmbracoIntegrationTest never runs composers, so the handler isn't there.
tags: [umbraco-testing, should-trigger]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, WebFetch]
---

My Umbraco 17 package (`src/Umbraco.Community.ReadingTime`) sets a `readingTime` property
(minutes, rounded up, 200 words a minute) on content whenever an editor saves a page that
has a `bodyText` property. The integration test project in `tests/` is set up but has no
tests yet.

Add an integration test showing that saving a page with about 400 words of body text sets
`readingTime` to 2.

Git and dotnet can't run here, so you can't build or run the tests; just write them.
