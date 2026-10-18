---
type: llm
focus: {source: file, path: tests/e2e/playwright.config.ts}
---
Context: every test drives the one demo site and its SQLite database. Playwright runs test
files in parallel workers by default, so tests that create and delete content collide and
SQLite reports the database as locked. Umbraco's own acceptance suite runs with `workers: 1`
for this reason, and says SQLite struggles even then.

PASS if this config runs the tests one at a time: `workers: 1` (with `fullyParallel` unset
or false).

FAIL if `workers` is unset or above 1, if `fullyParallel` is true, or if the file doesn't
exist.
