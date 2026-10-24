---
type: llm
focus: {source: file, path: docs/proposals/caching-options.md}
---
Check that each fact below appears somewhere in the file (a table, a list, a callout or the
text) and is clearly about the right option. Wording and number style may differ ("½ day"
for "half a day", "1–2" for "1-2").

- The feed takes about 400ms to rebuild today.
- The in-process options hold about 20MB per server.
- IMemoryCache is per server, so other servers serve a stale feed.
- The runtime cache needs a custom ICacheRefresher to clear on every server.
- HybridCache is only consistent across servers with Redis, and Umbraco 15 doesn't ship it.
- Redis adds about 2-5ms per read, and most Umbraco Cloud sites don't have Redis.
- Effort: half a day, 1-2 days, 2 days, and 3-4 days, each for its own option.

PASS if every fact is there.

FAIL if any is missing or tied to the wrong option. Name the missing fact.
