---
name: umbraco-testing
description: >-
  Writing a package's integration tests on Umbraco's own test base classes
  (`UmbracoIntegrationTest`, `UmbracoTestServerTestBase` from Umbraco.Cms.Tests.Integration):
  where the test host differs from a real site, so a test exercises the package instead of
  passing by default. Use when writing or reviewing an integration test for an Umbraco
  package, especially one that checks cached data, cache clearing or cache refreshers.
---

# Testing Umbraco packages

Setting up the test projects is `project-init`'s job (its backend tests step). How to shape a
test is `bdd-specs`'s, and testing repositories against a real database is `ef-core-data`'s.
This skill covers what Umbraco's test host leaves out compared to a real site.

Check base class members against the CMS source at the target release tag, under
`tests/Umbraco.Tests.Integration/` (`umbraco-cms-source`). Everything below was checked at
`release-17.7.1` and `release-18.2.1`.

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
