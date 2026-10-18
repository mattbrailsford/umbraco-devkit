#!/usr/bin/env bash
set -euo pipefail
d=src/Umbraco.Community.Redirects
t=tests/Umbraco.Community.Redirects.Tests.Integration
mkdir -p $d/Caching $d/Services $t

cat > $d/Umbraco.Community.Redirects.csproj <<'EOF'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Core" Version="[17.0.0, 18)" />
  </ItemGroup>
</Project>
EOF

cat > $d/RedirectsComposer.cs <<'EOF'
using Umbraco.Cms.Core.Composing;
using Umbraco.Cms.Core.DependencyInjection;

namespace Umbraco.Community.Redirects;

public class RedirectsComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder) => builder.AddRedirects();
}
EOF

cat > $d/UmbracoBuilderExtensions.cs <<'EOF'
using Microsoft.Extensions.DependencyInjection;
using Umbraco.Cms.Core.DependencyInjection;
using Umbraco.Community.Redirects.Caching;
using Umbraco.Community.Redirects.Services;

namespace Umbraco.Community.Redirects;

public static class UmbracoBuilderExtensions
{
    public static IUmbracoBuilder AddRedirects(this IUmbracoBuilder builder)
    {
        builder.Services.AddSingleton<IRedirectRuleService, RedirectRuleService>();
        builder.AddNotificationHandler<RedirectRulesChangedNotification, RedirectRulesChangedDistributedCacheHandler>();
        return builder;
    }
}
EOF

cat > $d/Services/RedirectRule.cs <<'EOF'
namespace Umbraco.Community.Redirects.Services;

public record RedirectRule(Guid Key, string From, string To, bool Permanent);
EOF

cat > $d/Services/IRedirectRuleService.cs <<'EOF'
namespace Umbraco.Community.Redirects.Services;

public interface IRedirectRuleService
{
    Task<IReadOnlyList<RedirectRule>> GetAllAsync();

    Task SaveAsync(RedirectRule rule);

    Task DeleteAsync(Guid key);
}
EOF

cat > $d/Services/RedirectRuleService.cs <<'EOF'
using System.Text.Json;
using Umbraco.Cms.Core.Cache;
using Umbraco.Cms.Core.Events;
using Umbraco.Cms.Core.Services;
using Umbraco.Community.Redirects.Caching;

namespace Umbraco.Community.Redirects.Services;

internal sealed class RedirectRuleService(
    IKeyValueService keyValueService,
    AppCaches appCaches,
    IEventAggregator eventAggregator) : IRedirectRuleService
{
    internal const string StorageKey = "Umbraco.Community.Redirects.Rules";

    public Task<IReadOnlyList<RedirectRule>> GetAllAsync()
    {
        // Read on every request by the redirect middleware, so keep it in memory.
        var rules = appCaches.RuntimeCache.GetCacheItem(
            RedirectRulesCacheRefresher.CacheKey,
            () => (IReadOnlyList<RedirectRule>)Load());
        return Task.FromResult(rules ?? []);
    }

    public async Task SaveAsync(RedirectRule rule)
    {
        var rules = Load().Where(r => r.Key != rule.Key).Append(rule).ToList();
        Store(rules);
        await eventAggregator.PublishAsync(new RedirectRulesChangedNotification());
    }

    public async Task DeleteAsync(Guid key)
    {
        Store(Load().Where(r => r.Key != key).ToList());
        await eventAggregator.PublishAsync(new RedirectRulesChangedNotification());
    }

    private List<RedirectRule> Load()
    {
        var json = keyValueService.GetValue(StorageKey);
        return string.IsNullOrEmpty(json) ? [] : JsonSerializer.Deserialize<List<RedirectRule>>(json) ?? [];
    }

    private void Store(List<RedirectRule> rules) =>
        keyValueService.SetValue(StorageKey, JsonSerializer.Serialize(rules));
}
EOF

cat > $d/Caching/RedirectRulesChangedNotification.cs <<'EOF'
using Umbraco.Cms.Core.Notifications;

namespace Umbraco.Community.Redirects.Caching;

public sealed class RedirectRulesChangedNotification : INotification;
EOF

cat > $d/Caching/RedirectRulesChangedDistributedCacheHandler.cs <<'EOF'
using Umbraco.Cms.Core.Cache;
using Umbraco.Cms.Core.Events;

namespace Umbraco.Community.Redirects.Caching;

// Sites can be load balanced: tell every server to drop its copy.
internal sealed class RedirectRulesChangedDistributedCacheHandler(DistributedCache distributedCache)
    : INotificationHandler<RedirectRulesChangedNotification>
{
    public void Handle(RedirectRulesChangedNotification notification) =>
        distributedCache.RefreshAll(RedirectRulesCacheRefresher.UniqueId);
}
EOF

cat > $d/Caching/RedirectRulesCacheRefresher.cs <<'EOF'
using Umbraco.Cms.Core.Cache;
using Umbraco.Cms.Core.Events;
using Umbraco.Cms.Core.Notifications;
using Umbraco.Cms.Core.Sync;

namespace Umbraco.Community.Redirects.Caching;

public sealed class RedirectRulesCacheRefresherNotification(object messageObject, MessageType messageType)
    : CacheRefresherNotification(messageObject, messageType);

public sealed class RedirectRulesCacheRefresher(
    AppCaches appCaches,
    IEventAggregator eventAggregator,
    ICacheRefresherNotificationFactory factory)
    : CacheRefresherBase<RedirectRulesCacheRefresherNotification>(appCaches, eventAggregator, factory)
{
    public static readonly Guid UniqueId = new("3f6b1c55-0a3e-4a51-9d0e-6a8f2b1e7c42");

    internal const string CacheKey = "Umbraco.Community.Redirects.Rules";

    public override Guid RefresherUniqueId => UniqueId;

    public override string Name => "Redirect rules cache refresher";

    public override void RefreshAll()
    {
        AppCaches.RuntimeCache.Clear(CacheKey);
        base.RefreshAll();
    }

    public override void Refresh(int id) => RefreshAll();

    public override void Refresh(Guid id) => RefreshAll();

    public override void Remove(int id) => RefreshAll();
}
EOF

cat > $d/Properties.cs <<'EOF'
using System.Runtime.CompilerServices;

[assembly: InternalsVisibleTo("Umbraco.Community.Redirects.Tests.Integration")]
EOF

cat > $t/Umbraco.Community.Redirects.Tests.Integration.csproj <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.12.0" />
    <PackageReference Include="NUnit" Version="3.14.0" />
    <PackageReference Include="NUnit3TestAdapter" Version="4.6.0" />
    <PackageReference Include="Umbraco.Cms.Tests.Integration" Version="17.3.0" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\Umbraco.Community.Redirects\Umbraco.Community.Redirects.csproj" />
  </ItemGroup>
</Project>
EOF

cat > $t/CustomGlobalSetupTeardown.cs <<'EOF'
using NUnit.Framework;

// No namespace, so it applies to the whole assembly.
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
EOF

cat > $t/RedirectsIntegrationTestBase.cs <<'EOF'
using Umbraco.Cms.Core.DependencyInjection;
using Umbraco.Cms.Tests.Common.Testing;
using Umbraco.Cms.Tests.Integration.Testing;

namespace Umbraco.Community.Redirects.Tests.Integration;

[UmbracoTest(Database = UmbracoTestOptions.Database.NewSchemaPerTest)]
public abstract class RedirectsIntegrationTestBase : UmbracoIntegrationTest
{
    // The test host doesn't run composers, so register the package the way its composer does.
    protected override void CustomTestSetup(IUmbracoBuilder builder) => builder.AddRedirects();
}
EOF

cat > $t/RedirectRuleServiceTests.cs <<'EOF'
using NUnit.Framework;
using Umbraco.Community.Redirects.Services;

namespace Umbraco.Community.Redirects.Tests.Integration;

[TestFixture]
public class RedirectRuleServiceTests : RedirectsIntegrationTestBase
{
    private IRedirectRuleService Service => GetRequiredService<IRedirectRuleService>();

    [Test]
    public async Task Saved_Rule_Is_Stored()
    {
        var rule = new RedirectRule(Guid.NewGuid(), "/old", "/new", Permanent: true);

        await Service.SaveAsync(rule);

        Assert.That(await Service.GetAllAsync(), Does.Contain(rule));
    }
}
EOF
