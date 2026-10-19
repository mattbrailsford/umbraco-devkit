# Step 7: End-to-end (e2e) tests

e2e tests drive the real backoffice in a browser against a running site. When they exist,
`feature-build`'s smoke step runs them first, and adds one for any task they don't cover.

## Detect

A `playwright.config.*` or an e2e/acceptance test folder. If one exists, keep it.

## Default if missing: Playwright with Umbraco's helpers

Ask first. Needs a site to run against, usually the demo/test site the package template
generates. If there isn't one, skip this step and say so.

- Put it in its own folder, e.g. `tests/<Package>.Tests.E2E/`, with its own `package.json`.
- Install:
  ```bash
  npm install --save-dev @playwright/test @umbraco-cms/acceptance-test-helpers@<CMS version>
  npx playwright install chromium
  ```
  `@umbraco-cms/acceptance-test-helpers` is the CMS's own Playwright helper package (login,
  API helpers, builders), versioned with the CMS from 17.3. Older projects use
  `@umbraco/playwright-testhelpers`. Its login setup, environment variables and config are
  in `umbraco-test-setup`'s "End-to-end tests" section, and test patterns in the official
  Backoffice Testing Skills plugin, if installed; the package's README imports from a
  name that doesn't exist on npm.
- `playwright.config.ts`:
  - `baseURL` built from the worktree's port (`getPort()` from `worktree-dev-port`, see step
    3), so each worktree tests its own site. Without step 3, use an environment variable.
    Set `process.env.URL` to the same address: Umbraco's helpers read `URL`, not `baseURL`.
  - `webServer` to start the demo site (`dotnet run --project <demo site>`) if it isn't
    already running.
  - Backoffice login details from environment variables or a gitignored `.env`. Never commit
    them.

## Check

`npx playwright test` starts (or reaches) the site and exits cleanly (zero tests is fine).
Don't add sample tests.

## Record

Add to `CLAUDE.md`'s "Build & test" section: how to start the demo site, which environment
variables the tests need (names only, never values), and the `npx playwright test` command.
