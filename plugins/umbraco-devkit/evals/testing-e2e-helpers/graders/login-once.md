---
type: llm
focus: {source: file, path: tests/e2e/playwright.config.ts}
---
Context: Umbraco's API helpers read their access tokens from the Playwright storage state
file named by the `STORAGE_STATE_PATH` environment variable. The usual pattern logs in once
in a setup project, saves the storage state to that file, and gives the test projects the
same file as `storageState`.

PASS if this config has a login step that runs once before the tests (a setup project the
test project depends on, or `globalSetup`), and the test project's `storageState` is the
file named by `process.env.STORAGE_STATE_PATH` (directly, or through a constant that reads
it, with or without a default).

FAIL if there's no shared login step, if `storageState` is a fixed path that doesn't come
from `STORAGE_STATE_PATH` (the API helpers would read a different file), or if the file
doesn't exist.
