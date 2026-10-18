---
description: Testing a package's Management API endpoint on UmbracoTestServerTestBase; the test server only finds the CMS's controllers, so the package's own returns 404.
tags: [umbraco-testing, should-trigger]
# covers: ["Test server: add the package's controllers"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, WebFetch]
---

My Umbraco 17 package (`src/Umbraco.Community.ReadingTime`) has a Management API endpoint,
`ReadingTimeController.Get`, that the backoffice calls to preview a page's reading time.
The integration test project in `tests/` is set up but has no tests yet.

Add integration tests for the endpoint, going through HTTP: a backoffice user gets the
minutes for a page with about 400 words of `bodyText`, an unknown key gets 404, and a
request with no user gets 401.

Git and dotnet can't run here, so you can't build or run the tests; just write them.
