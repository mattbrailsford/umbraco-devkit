#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/notes docs/proposals
cat > docs/notes/caching.md <<'MD'
caching for the package's product feed (rebuilt from content on every request today, ~400ms on big sites)

option 1: IMemoryCache
- per server. load balanced = each server has its own copy, so editors see stale feeds on other servers until expiry unless we also hook a cache refresher
- invalidate: remove key from a ContentPublishedNotification handler, but only on the server that published
- memory: whole feed in process, ~20MB on the biggest customer site
- no new dependency
- works on Umbraco 15 and 16
- effort: small, half a day

option 2: Umbraco AppCaches.RuntimeCache
- per server, but Umbraco's distributed cache refreshers clear it on every server, so load balancing is handled if we add a custom ICacheRefresher
- invalidate: ClearByKey from our cache refresher, runs on all servers
- memory: same as option 1, ~20MB
- no new dependency
- works on Umbraco 15 and 16
- effort: medium, 1-2 days (cache refresher + payload)

option 3: HybridCache (Microsoft.Extensions.Caching.Hybrid)
- in-memory plus optional distributed second level; tag-based invalidation
- load balanced: only consistent if a distributed backend (Redis) is configured, otherwise same as option 1
- memory: ~20MB per server plus Redis if used
- new dependency: Microsoft.Extensions.Caching.Hybrid 9.x; Umbraco 16 already uses it, Umbraco 15 doesn't, so we'd ship it ourselves there
- effort: medium, 2 days

option 4: IDistributedCache with Redis
- one shared copy, consistent across servers
- invalidate: remove key once, every server sees it
- memory: none in process; network hop on every read (~2-5ms)
- new dependency: Microsoft.Extensions.Caching.StackExchangeRedis, and every customer needs a Redis instance, which most Umbraco Cloud sites don't have
- works on Umbraco 15 and 16
- effort: large, 3-4 days including docs for setting up Redis
MD
