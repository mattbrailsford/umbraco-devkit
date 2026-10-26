#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/notes docs/proposals
cat > docs/notes/rate-limiting.md <<'MD'
rate limiting for the package's public search endpoint (/api/acme-search/query)

- one site got hammered last month: ~4k req/min from one IP, CPU pegged, site down 20 min
- use ASP.NET Core's built-in RateLimiter middleware (Microsoft.AspNetCore.RateLimiting), no new dependency
- partition by client IP. behind Cloudflare / Azure Front Door the IP is in a forwarded header, so needs ForwardedHeaders configured first, otherwise everyone shares one bucket
- fixed window vs sliding window vs token bucket?? token bucket handles bursts from autocomplete better
- limit per IP: no idea. 60/min? autocomplete fires per keystroke so maybe higher
- what to return: 429 with Retry-After
- should logged-in backoffice users be exempt? they use the same endpoint for the search preview dashboard
- config: Acme:Search:RateLimit:{Enabled, PermitsPerMinute, ...}. Enabled by default or opt-in? opt-in is safer for upgrades but leaves sites exposed
- load balanced sites: built-in limiter is per server, so N servers = N x the limit. distributed (Redis) is out of scope for now
- log a warning once per minute per IP that gets limited, not per request
MD
