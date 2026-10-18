---
name: umbraco-testing
description: >-
  Testing an Umbraco package on Umbraco's own test tooling: integration tests on
  `UmbracoIntegrationTest` and `UmbracoTestServerTestBase` (Umbraco.Cms.Tests.Integration),
  component tests of backoffice elements built on `@umbraco-cms/backoffice`, and Playwright
  end-to-end tests on Umbraco's helpers. Covers what the test project must add for them to
  run, and where the test host differs from a real site, so a test exercises the package
  instead of passing by default. Use when adding a test project, or writing or reviewing a
  test, for an Umbraco package's C# code, backoffice elements or backoffice journeys,
  especially one that checks cached data, a Management API endpoint, a context or translated
  text.
---

# Testing Umbraco packages

`project-init` creates the test projects (its backend and frontend tests steps). How to
shape a test is `bdd-specs`'s job, and testing repositories against a real database is
`ef-core-data`'s. This skill covers what Umbraco's test tooling needs from a package's test
project, and what its test host leaves out compared to a real site.

Check base class members against the CMS source at the target release tag, under
`tests/Umbraco.Tests.Integration/` (`umbraco-cms-source`). The C# sections were checked at
`release-17.7.1` and `release-18.2.1`. The backoffice section was run against
`@umbraco-cms/backoffice` 17.7.1 in Web Test Runner, and the end-to-end snippets
type-checked against `@umbraco-cms/acceptance-test-helpers` 17.7.1.

## Test project setup: what Umbraco's own test project provides

`Umbraco.Cms.Tests.Integration` is the CMS's own test project, published as a package. Two
things that make it work stay behind in the CMS repo, so a package's test project adds them
itself. Without them, every test with a database fails before it starts.

- **A global setup class, outside any namespace.** The package's `GlobalSetupTeardown` loads
  the test settings, but it's an NUnit `[SetUpFixture]`, which only runs for tests in its own
  assembly. Call it from one in yours. With no namespace it applies to every test in the
  project:

  ```csharp
  using NUnit.Framework;

  [SetUpFixture]
  public class CustomGlobalSetupTeardown
  {
      private static GlobalSetupTeardown? _setupTearDown;

      [OneTimeSetUp]
      public void SetUp()
      {
          _setupTearDown = new GlobalSetupTeardown();
          _setupTearDown.SetUp();
      }

      [OneTimeTearDown]
      public void TearDown() => _setupTearDown?.TearDown();
  }
  ```

  Without it, `Tests:Database:DatabaseType` is never read, and the first database test
  throws "Unsupported test database provider".
- **`appsettings.Tests.json` in the output folder.** `GlobalSetupTeardown` requires it. The
  package adds one to the project without copying it to the output, so add the project's
  own and copy it:

  ```json
  {
    "Tests": {
      "Database": {
        "DatabaseType": "SQLite",
        "PrepareThreadCount": 4,
        "SchemaDatabaseCount": 4,
        "EmptyDatabasesCount": 2,
        "SQLServerMasterConnectionString": ""
      }
    }
  }
  ```

  ```xml
  <ItemGroup>
    <Content Include="appsettings.Tests.json" CopyToOutputDirectory="PreserveNewest" />
  </ItemGroup>
  ```

  An optional `appsettings.Tests.Local.json` overrides it, for example to run against SQL
  Server. Copy it the same way and keep it out of git.

Source: `tests/Umbraco.Tests.Integration/GlobalSetupTeardown.cs` and the package's `.nuspec`,
[Integration testing](https://docs.umbraco.com/umbraco-cms/develop-with-umbraco/testing-and-debugging/integration-testing).

## Test server: add the package's controllers

`UmbracoTestServerTestBase`, and `ManagementApiTest<T>` built on it, registers controllers
from the CMS assemblies and `Umbraco.Tests.Integration` only. It names that assembly as the
application, and MVC finds no others from it in a package's test output. So every request to
the package's own controllers returns 404, even one the test expects to be 401. Add the
package's assembly:

```csharp
protected override void CustomMvcSetup(IMvcBuilder mvcBuilder) =>
    mvcBuilder.AddApplicationPart(typeof(MyPackageController).Assembly);
```

The same goes for controllers declared in the test project itself. Composers do run on the
test server (unlike `UmbracoIntegrationTest`), so the package's services are there.

Source: `tests/Umbraco.Tests.Integration/TestServerTest/UmbracoTestServerTestBase.cs`
(`ConfigureServices`) and `Implementations/TestHelper.cs` (`ApplicationName`).

## Cache tests: switch caching and refreshers back on

`UmbracoIntegrationTest` is set up for isolated, fast tests, not for caching. By default:

- **Caching is off.** It registers `AppCaches.NoCache`, so `RuntimeCache.GetCacheItem`
  calls its factory every time and nothing is ever stale.
- **Cache refreshers never run.** It registers a no-op `IServerMessenger`, so
  `DistributedCache.Refresh*` and `RefreshAll` never reach any `ICacheRefresher`.
- **Umbraco's own `*DistributedCacheNotificationHandler` classes aren't registered**, so a
  core cache isn't cleared by the notification that clears it on a site.

So a test that reads, saves and reads again passes even with the cache clearing deleted.
When a test covers anything cached, override `CustomTestSetup` to turn both back on:

```csharp
protected override void CustomTestSetup(IUmbracoBuilder builder)
{
    builder.AddMyPackage(); // or whatever registers the package

    builder.Services.AddUnique(_ => new AppCaches(
        new DeepCloneAppCache(new ObjectCacheAppCache()),
        NoAppCache.Instance,
        new IsolatedCaches(_ => new DeepCloneAppCache(new ObjectCacheAppCache()))));

    builder.Services.AddUnique<IServerMessenger>(sp =>
        new LocalServerMessenger(sp.GetRequiredService<IJsonSerializer>()));
}

// Runs cache refreshers on this server, straight away. The CMS has its own copy, but it's internal.
private sealed class LocalServerMessenger(IJsonSerializer serializer)
    : ServerMessengerBase(distributedEnabled: false, serializer)
{
    public override void SendMessages() { }

    public override void Sync() { }

    protected override void DeliverRemote(
        ICacheRefresher refresher, MessageType messageType, IEnumerable<object>? ids = null, string? json = null) { }
}
```

- **If the test relies on Umbraco clearing one of its own caches** (content, a data type, a
  language), also register that core handler, for example
  `builder.AddNotificationHandler<LanguageDeletedNotification, LanguageDeletedDistributedCacheNotificationHandler>()`.
  The package's own handlers come with the package's registration.
- **Fill the cache first.** Read once, change through the real path (the service or
  endpoint editors use), then read again. A test that never reads before the change can't
  see a stale value.
- **Prove it can fail.** Remove the refresh call, and the test must go red. If it stays
  green, the harness defaults are still in place.

Source: `tests/Umbraco.Tests.Integration/DependencyInjection/UmbracoBuilderExtensions.cs`
(`AddTestServices`) and the CMS's own `tests/Umbraco.Tests.Integration/CLAUDE.md`.

## Backoffice element tests: a controller host and loaded translations

A test of an element built on `@umbraco-cms/backoffice` needs no import map. With Web Test
Runner's `nodeResolve: true`, the imports resolve from `node_modules` (`@umbraco-cms/backoffice`
as a dev dependency at the project's CMS version). The esbuild plugin needs the project's
`tsconfig.json`, or the decorators reach the browser untransformed and the test file fails
with a `SyntaxError`. Two things a plain Lit test doesn't need:

- **An Umbraco controller host.** Contexts and controllers (`UmbContextBase`,
  `consumeContext`, `observe`) attach to a host. Create the context on a test element that
  extends `UmbLitElement`, and put the element under test inside it. On a plain `<div>` the
  context's constructor throws `addUmbController is not a function`.
- **The package's translations, registered and loaded.** `this.localize.term(...)` renders
  the key (`readingTime_minutes`) until both are done: register the package's `localization`
  manifests with `umbExtensionsRegistry`, then call `umbLocalizationRegistry.loadLanguage`.
  The registry comes from `@umbraco-cms/backoffice/localization`, not
  `@umbraco-cms/backoffice/localization-api`.
  The strings load asynchronously, so wait for the text.

```ts
import { expect, fixture, html, waitUntil } from '@open-wc/testing';
import { customElement } from '@umbraco-cms/backoffice/external/lit';
import { UmbLitElement } from '@umbraco-cms/backoffice/lit-element';
import { umbExtensionsRegistry } from '@umbraco-cms/backoffice/extension-registry';
import { umbLocalizationRegistry } from '@umbraco-cms/backoffice/localization';
import { manifests } from '../manifests.js';
import { ReadingTimeContext } from './reading-time.context.js';
import './reading-time-badge.element.js';

@customElement('test-host')
class TestHostElement extends UmbLitElement {}

describe('reading-time-badge', () => {
	before(() => {
		umbExtensionsRegistry.registerMany(manifests.filter((m) => m.type === 'localization'));
		umbLocalizationRegistry.loadLanguage('en');
	});

	it('shows the minutes from the context', async () => {
		const host = await fixture<TestHostElement>(html`<test-host></test-host>`);
		new ReadingTimeContext(host).setMinutes(3);
		const badge = document.createElement('reading-time-badge');
		host.appendChild(badge);

		await waitUntil(() => badge.shadowRoot?.textContent?.includes('3 min read'));
		expect(badge.shadowRoot!.textContent).to.contain('3 min read');
	});
});
```

To stand in for a context, write a fake that extends `UmbContextBase` with the same token
and create it on the host. A plain object passed to `provideContext` throws
`getHostElement is not a function`.

The CMS's own test utilities (`@umbraco-cms/internal/test-utils`) aren't published, so don't
import them.

## End-to-end tests: Umbraco's Playwright helpers

Umbraco's Playwright helpers (login, `umbracoApi` for test data, `umbracoUi` for the
backoffice, JSON builders) are published as **`@umbraco-cms/acceptance-test-helpers`**,
versioned with the CMS from 17.3. Install the version matching the site.

- **Not the old names.** `@umbraco/playwright-testhelpers` and `@umbraco/json-models-builders`
  are deprecated. The package's own README examples import from
  `@umbraco/acceptance-test-helpers`, which doesn't exist on npm. Import from
  `@umbraco-cms/acceptance-test-helpers`.
- **Configure through environment variables**, never committed: `URL` (the site's address;
  the helpers use it, not Playwright's `baseURL`, and it defaults to
  `https://localhost:44339`, the CMS repo's own port), `UMBRACO_USER_LOGIN`,
  `UMBRACO_USER_PASSWORD`, and `STORAGE_STATE_PATH`. The API helpers read their tokens from
  the storage state file, so `STORAGE_STATE_PATH` names the same file the setup saves.
- **Log in once**, in a setup project, and give the tests that state.
- **Run one test at a time** (`workers: 1`). Every test shares one site and database.
  Umbraco's own suite runs this way, and asks for SQL Server or LocalDb because SQLite can't
  keep up even then. On a SQLite demo site, keep runs serial.

```ts
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';
import 'dotenv/config';

export const STORAGE_STATE = process.env.STORAGE_STATE_PATH ?? 'playwright/.auth/user.json';

export default defineConfig({
	testDir: './tests',
	workers: 1,
	use: { baseURL: process.env.URL, ignoreHTTPSErrors: true },
	projects: [
		{ name: 'setup', testMatch: '**/*.setup.ts' },
		{
			name: 'e2e',
			testMatch: '**/*.spec.ts',
			dependencies: ['setup'],
			use: { ...devices['Desktop Chrome'], storageState: STORAGE_STATE },
		},
	],
});
```

```ts
// tests/auth.setup.ts
import { test as setup } from '@playwright/test';
import { UiHelpers } from '@umbraco-cms/acceptance-test-helpers';
import { STORAGE_STATE } from '../playwright.config';

setup('authenticate', async ({ page }) => {
	const umbracoUi = new UiHelpers(page);
	await umbracoUi.goToBackOffice();
	await umbracoUi.login.enterEmail(process.env.UMBRACO_USER_LOGIN!);
	await umbracoUi.login.enterPassword(process.env.UMBRACO_USER_PASSWORD!);
	await umbracoUi.login.clickLoginButtonAndWaitForBackOffice();
	await page.context().storageState({ path: STORAGE_STATE });
});
```

Tests then import `test` from the package and get `umbracoApi` and `umbracoUi` as fixtures.
The config loads `.env` with `dotenv` (a dev dependency). Keep `.env` and
`playwright/.auth/` out of git.

Source: `tests/Umbraco.Tests.AcceptanceTest/` in the CMS repo (`playwright.config.ts`,
`tests/auth.setup.ts`, `README.md`) and the package's `dist/umbraco.config.js`.
