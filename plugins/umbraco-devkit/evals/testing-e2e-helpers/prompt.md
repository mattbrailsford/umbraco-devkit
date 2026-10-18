---
description: First Playwright test for a package against its SQLite demo site; Umbraco's helpers moved to a new npm name in 17.3, and the shared SQLite site needs serial runs.
tags: [umbraco-testing, should-trigger]
# covers: ["End-to-end tests: Umbraco's Playwright helpers"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, WebFetch]
---

My Umbraco 17.7 package shows a "Reading time" view on documents (backoffice code in
`Client/`). The demo site in `demo/ReadingTime.Demo` is what I run it against.

Set up Playwright end-to-end tests in `tests/e2e/` with a first test: create a document with
about 400 words of body text, open it in the backoffice, and check the Reading time view
shows "2 min read". Use Umbraco's own Playwright helpers for logging in and creating the
test data rather than hand-written selectors. More tests will follow.

npm, dotnet and git can't run here, so just write the files; I'll install and run them.
