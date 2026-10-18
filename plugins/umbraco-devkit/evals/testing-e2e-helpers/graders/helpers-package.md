---
type: llm
weight: 2
focus: {source: file, path: tests/e2e/package.json}
---
Context: from CMS 17.3, Umbraco's Playwright helpers are published as
`@umbraco-cms/acceptance-test-helpers`, versioned with the CMS. `@umbraco/playwright-testhelpers`
and `@umbraco/json-models-builders` are deprecated, and `@umbraco/acceptance-test-helpers`
(the name in the package's own README examples) doesn't exist on npm.

PASS if this `package.json` depends on `@umbraco-cms/acceptance-test-helpers` at a 17.x
version or range.

FAIL if it depends on `@umbraco/playwright-testhelpers`, `@umbraco/json-models-builders` or
`@umbraco/acceptance-test-helpers`, if it has no Umbraco helper package, or if the file
doesn't exist.
