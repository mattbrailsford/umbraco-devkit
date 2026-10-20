# Step 6: Frontend tests

Only if the project has a `Client/` frontend. These are component tests: Lit elements
rendered in a real browser. Full journeys through a running backoffice are step 7.

## Detect

A `web-test-runner.config.*`, a `vitest.config.*`, or `*.test.ts` files with a `test` script
in `package.json`. If one exists, keep it.

## Default if missing: Web Test Runner

Ask first. Web Test Runner is the default because the CMS backoffice uses it, and it renders
Lit components into a real browser's shadow DOM without extra setup.

```bash
npm install --save-dev @web/test-runner @web/test-runner-playwright @web/dev-server-esbuild @open-wc/testing
npx playwright install chromium
```

`web-test-runner.config.mjs`, a trimmed version of the CMS backoffice's own:

```js
import { esbuildPlugin } from '@web/dev-server-esbuild';
import { playwrightLauncher } from '@web/test-runner-playwright';

export default {
	files: ['./src/**/*.test.ts'],
	nodeResolve: true,
	browsers: [playwrightLauncher({ product: 'chromium' })],
	plugins: [esbuildPlugin({ ts: true, tsconfig: './tsconfig.json', target: 'auto' })],
};
```

Add `"test": "web-test-runner"` to `package.json`.

With `nodeResolve: true`, `@umbraco-cms/backoffice/*` imports resolve from `node_modules`; no
import map is needed. What a test of a backoffice element needs beyond that (a controller
host, the package's translations) is in `umbraco-backoffice-testing`. Test patterns and API
mocking are in the official Backoffice Testing Skills plugin, if installed.

## Check

`npm test` runs and exits cleanly (zero tests is fine). Don't add sample tests.

## Record

Add `npm test` (run from the `Client/` folder) to `CLAUDE.md`'s "Build & test" section.
