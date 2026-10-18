---
type: llm
weight: 2
focus: {source: file, path: docs/plans/subscriber-export/SPEC.md}
---
Context: the brief says the biggest sites have about 60,000 members and run on a small
shared App Service plan that keeps serving the public site during the nightly sync.

PASS if SPEC.md states the feature's non-functional targets as things a test or reviewer
can check: at least one target for the 60,000-member scale given as a number or a concrete
condition (for example a page size or row limit per request, a response-time or memory
bound for the full export, or "never loads all subscriptions into memory at once").

FAIL if SPEC.md has no such targets, if scale or speed appears only as vague words
("fast", "scales well", "efficient"), or if the only mention of scale is rationale
without a target someone could test.
