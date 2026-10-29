---
type: regex
pattern: '^(?=[\s\S]*400\s?ms)(?=[\s\S]*20\s?MB)(?=[\s\S]*ICacheRefresher)(?=[\s\S]*Redis)(?=[\s\S]*2\s?[-–to ]+\s?5\s?ms)(?=[\s\S]*Cloud)(?=[\s\S]*(?:half a day|½))(?=[\s\S]*1\s?[-–to ]+\s?2 days)(?=[\s\S]*3\s?[-–to ]+\s?4 days)(?=[\s\S]*stale)'
target: {source: file, path: docs/proposals/caching-options.md}
---
