---
type: llm
weight: 2
focus: trace
---
Context: `UmbracoIntegrationTest` registers `AppCaches.NoCache` and a no-op
`IServerMessenger`. With those defaults the runtime cache never holds anything and
`DistributedCache.RefreshAll` never reaches `RedirectRulesCacheRefresher`, so a test that
saves a rule and reads it back passes even if the handler or refresher is deleted.

PASS if the new tests' setup (in the test class or the shared base class) both:
1. replaces `AppCaches.NoCache` with a real cache (for example `AppCaches` built on
   `ObjectCacheAppCache`, or `AppCaches.Create(...)`), so `GetAllAsync` actually caches; and
2. makes distributed cache refreshes run in the test, for example by registering an
   `IServerMessenger` that delivers locally and synchronously, or by otherwise invoking the
   package's refresher through `DistributedCache`.
The tests must also read the rules once before saving or deleting, so a stale cached list
would be returned if the refresh didn't happen.

FAIL if the tests keep the harness's default caches or messenger, so they would pass with
the handler or refresher removed; if they call the refresher or clear the cache by hand
instead of going through the save or delete path; or if no tests were written.
