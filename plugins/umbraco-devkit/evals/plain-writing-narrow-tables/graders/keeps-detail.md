---
type: llm
focus: {source: file, path: docs/api.md}
---
PASS if docs/api.md keeps all of these: the base path; the take range 1-200 and default 50;
the 404 when a product has no stock record; the level >= 0 and 200-character reason limits;
the 409 when reserved exceeds the new level; the quantity range 1-1000; the 15-minute
reservation expiry; which endpoints need Content section access and which need Settings.

FAIL if any of these is missing or loses its number.
