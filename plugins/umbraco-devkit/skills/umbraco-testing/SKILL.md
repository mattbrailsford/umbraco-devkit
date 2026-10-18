---
name: umbraco-testing
description: >-
  Writing a package's integration tests on Umbraco's own test base classes
  (`UmbracoIntegrationTest`, `UmbracoTestServerTestBase` from Umbraco.Cms.Tests.Integration):
  what the test project must add for them to run, and where the test host differs from a
  real site, so a test exercises the package instead of passing by default. Use when adding
  an integration test project, or writing or reviewing an integration test, for an Umbraco
  package, especially one that checks cached data, cache clearing or cache refreshers.
---

# Testing Umbraco packages

`project-init`'s backend tests step creates the test projects. How to shape a test is
`bdd-specs`'s job, and testing repositories against a real database is `ef-core-data`'s.
This skill covers what Umbraco's test helpers need from a package's test project, and what
their test host leaves out compared to a real site.

Check base class members against the CMS source at the target release tag, under
`tests/Umbraco.Tests.Integration/` (`umbraco-cms-source`). Everything below was checked at
`release-17.7.1` and `release-18.2.1`.

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
