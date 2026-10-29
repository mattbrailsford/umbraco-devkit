---
type: llm
focus: {source: file, path: docs/proposals/rate-limiting.md}
---
PASS if the proposal keeps: the incident (about 4,000 requests a minute from one IP, about 20
minutes down); the built-in ASP.NET Core rate limiter with no new dependency; that forwarded
headers must be configured or everyone shares one bucket; 429 with Retry-After; that on a
load-balanced site the limit is per server and a distributed limiter is out of scope; and
the once-per-minute-per-IP warning log.

FAIL if any of these is missing.
