#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'MD'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Open source; trunk branch: `main`.
Sites using it are often load balanced.

## Build & test

`dotnet build` and `dotnet test` from the repo root.
MD
cat > CONTRIBUTING.md <<'MD'
# Contributing

- Target `main`.
- New behavior comes with unit tests.
MD
mkdir -p src/Umbraco.Community.TagCloud/Services src/Umbraco.Community.TagCloud/Caching tests/Umbraco.Community.TagCloud.Tests
cat > src/Umbraco.Community.TagCloud/Umbraco.Community.TagCloud.csproj <<'CS'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup><TargetFramework>net10.0</TargetFramework><Nullable>enable</Nullable></PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" Version="[17.0.0, 18.0.0)" />
  </ItemGroup>
</Project>
CS
cat > src/Umbraco.Community.TagCloud/Caching/CacheKeys.cs <<'CS'
namespace Umbraco.Community.TagCloud.Caching;

public static class CacheKeys
{
    /// <summary>Every tag cloud cache entry starts with this, so one call can clear them all.</summary>
    public const string Prefix = "TagCloud_";
}
CS
cat > src/Umbraco.Community.TagCloud/Caching/TagCloudCacheHandler.cs <<'CS'
using Umbraco.Cms.Core.Cache;
using Umbraco.Cms.Core.Events;
using Umbraco.Cms.Core.Notifications;

namespace Umbraco.Community.TagCloud.Caching;

// Runs on every server when content changes, so tag counts never go stale on any of them.
public class TagCloudCacheHandler(AppCaches appCaches)
    : INotificationHandler<ContentCacheRefresherNotification>
{
    public void Handle(ContentCacheRefresherNotification notification) =>
        appCaches.RuntimeCache.ClearByKey(CacheKeys.Prefix);
}
CS
cat > src/Umbraco.Community.TagCloud/TagCloudComposer.cs <<'CS'
using Umbraco.Cms.Core.Composing;
using Umbraco.Cms.Core.DependencyInjection;
using Umbraco.Cms.Core.Notifications;
using Umbraco.Community.TagCloud.Caching;
using Umbraco.Community.TagCloud.Services;

namespace Umbraco.Community.TagCloud;

public class TagCloudComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder)
    {
        builder.Services.AddSingleton<TagCloudService>();
        builder.AddNotificationHandler<ContentCacheRefresherNotification, TagCloudCacheHandler>();
    }
}
CS
cat > src/Umbraco.Community.TagCloud/Services/TagCloudService.cs <<'CS'
using Umbraco.Cms.Core.Cache;
using Umbraco.Cms.Core.Services;
using Umbraco.Community.TagCloud.Caching;
using Umbraco.Extensions;

namespace Umbraco.Community.TagCloud.Services;

public class TagCloudService(ITagService tagService, AppCaches appCaches)
{
    public IReadOnlyList<(string Text, int Weight)> GetCloud(string group) =>
        appCaches.RuntimeCache.GetCacheItem(
            $"{CacheKeys.Prefix}group_{group}",
            () => Build(tagService.GetAllContentTags(group)))!;

    private static IReadOnlyList<(string Text, int Weight)> Build(IEnumerable<Umbraco.Cms.Core.Models.ITag> tags) =>
        tags.OrderByDescending(t => t.NodeCount)
            .Select(t => (t.Text, t.NodeCount))
            .ToList();
}
CS
git add -A && git commit -q -m "feat: cached tag cloud"

# The contributor's branch.
cat > src/Umbraco.Community.TagCloud/Services/TagCloudService.cs <<'CS'
using Umbraco.Cms.Core.Cache;
using Umbraco.Cms.Core.Services;
using Umbraco.Community.TagCloud.Caching;
using Umbraco.Extensions;

namespace Umbraco.Community.TagCloud.Services;

public class TagCloudService(ITagService tagService, AppCaches appCaches)
{
    public IReadOnlyList<(string Text, int Weight)> GetCloud(string group) =>
        appCaches.RuntimeCache.GetCacheItem(
            $"{CacheKeys.Prefix}group_{group}",
            () => Build(tagService.GetAllContentTags(group)))!;

    /// <summary>The tag cloud for one culture, for multilingual sites.</summary>
    public IReadOnlyList<(string Text, int Weight)> GetCloud(string group, string culture) =>
        appCaches.RuntimeCache.GetCacheItem(
            $"{CacheKeys.Prefix}group_{group}_{culture.ToLowerInvariant()}",
            () => Build(tagService.GetAllContentTags(group, culture)))!;

    private static IReadOnlyList<(string Text, int Weight)> Build(IEnumerable<Umbraco.Cms.Core.Models.ITag> tags) =>
        tags.OrderByDescending(t => t.NodeCount)
            .Select(t => (t.Text, t.NodeCount))
            .ToList();
}
CS
git add -A && git diff --cached HEAD > PR.diff
git commit -q -m "feat: tag cloud per culture"
cat > PR.json <<'JSON'
{
  "number": 151,
  "title": "Add a tag cloud per culture",
  "author": { "login": "lang-dev-12" },
  "baseRefName": "main",
  "headRefName": "feat/culture-cloud",
  "body": "On multilingual sites the cloud mixes every language's tags. This adds `GetCloud(group, culture)`, cached like the existing one.",
  "files": ["src/Umbraco.Community.TagCloud/Services/TagCloudService.cs"]
}
JSON
