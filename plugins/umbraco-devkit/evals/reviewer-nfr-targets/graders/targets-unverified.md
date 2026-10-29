---
type: llm
weight: 2
---
Context: SPEC.md's targets (two still listed as guesses) say a page at take=500 returns in under 1
second at p95 with 60,000 members on SQL Server and SQLite, and a full export finishes in
under 5 minutes. The branch's tests seed at most 30 members, on SQLite only, and time
nothing.

PASS if the review says these timing targets are not verified by anything in the branch (no
load, timing or large-data test, or no measurement on both providers) and treats that as
something to fix or settle before the PR, not as an aside.

FAIL if the review does not raise the unverified timing targets, or only says the code
"looks efficient" or "should meet" them.
