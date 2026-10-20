#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'MD'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Build & test

`dotnet build` and `dotnet test` from the repo root.

`TagRanking` is public API: other packages call it, so it stays `public`.
MD
mkdir -p src/Umbraco.Community.TagCloud/Services tests/Umbraco.Community.TagCloud.Tests
cat > src/Umbraco.Community.TagCloud/Umbraco.Community.TagCloud.csproj <<'CS'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup><TargetFramework>net10.0</TargetFramework><Nullable>enable</Nullable></PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" Version="[17.0.0, 18.0.0)" />
  </ItemGroup>
</Project>
CS
cat > tests/Umbraco.Community.TagCloud.Tests/Umbraco.Community.TagCloud.Tests.csproj <<'CS'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup><TargetFramework>net10.0</TargetFramework><Nullable>enable</Nullable></PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageReference Include="NUnit" Version="4.3.2" />
    <PackageReference Include="NUnit3TestAdapter" Version="5.0.0" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="../../src/Umbraco.Community.TagCloud/Umbraco.Community.TagCloud.csproj" />
  </ItemGroup>
</Project>
CS
cat > src/Umbraco.Community.TagCloud/Services/TagRanking.cs <<'CS'
namespace Umbraco.Community.TagCloud.Services;

public record RankedTag(string Text, int Count);

public static class TagRanking
{
    /// <summary>Returns one page of tags, most used first.</summary>
    /// <param name="page">The page number, starting at 1.</param>
    public static IReadOnlyList<RankedTag> GetPage(IEnumerable<RankedTag> tags, int page, int size) =>
        Ordered(tags).Skip(page * size).Take(size).ToList();

    private static IOrderedEnumerable<RankedTag> Ordered(IEnumerable<RankedTag> tags) =>
        tags.OrderByDescending(t => t.Count).ThenBy(t => t.Text, StringComparer.OrdinalIgnoreCase);
}
CS
cat > tests/Umbraco.Community.TagCloud.Tests/TagRankingTests.cs <<'CS'
using NUnit.Framework;
using Umbraco.Community.TagCloud.Services;

namespace Umbraco.Community.TagCloud.Tests;

public class TagRankingTests
{
    private static readonly RankedTag[] Tags = [new("news", 5), new("events", 9), new("blog", 2)];

    [Test]
    public void GetPage_OrdersByCount() =>
        Assert.That(TagRanking.GetPage(Tags, 0, 3).Select(t => t.Text), Is.EqualTo(new[] { "events", "news", "blog" }));
}
CS
git add -A && git commit -q -m "feat(ranking): page tags by use"

# The change under review: a top-N helper for the dashboard.
cat > src/Umbraco.Community.TagCloud/Services/TagRanking.cs <<'CS'
namespace Umbraco.Community.TagCloud.Services;

public record RankedTag(string Text, int Count);

public static class TagRanking
{
    /// <summary>Returns one page of tags, most used first.</summary>
    /// <param name="page">The page number, starting at 1.</param>
    public static IReadOnlyList<RankedTag> GetPage(IEnumerable<RankedTag> tags, int page, int size) =>
        Ordered(tags).Skip(page * size).Take(size).ToList();

    private static IOrderedEnumerable<RankedTag> Ordered(IEnumerable<RankedTag> tags) =>
        tags.OrderByDescending(t => t.Count).ThenBy(t => t.Text, StringComparer.OrdinalIgnoreCase);

    /// <summary>Returns the <paramref name="count"/> most used tags.</summary>
    public static IReadOnlyList<RankedTag> GetTop(IEnumerable<RankedTag> tags, int count)
    {
        ArgumentNullException.ThrowIfNull(tags);
        ArgumentOutOfRangeException.ThrowIfNegative(count);
        return Ordered(tags).Take(count).ToList();
    }
}
CS
cat > tests/Umbraco.Community.TagCloud.Tests/TagRankingTests.cs <<'CS'
using NUnit.Framework;
using Umbraco.Community.TagCloud.Services;

namespace Umbraco.Community.TagCloud.Tests;

public class TagRankingTests
{
    private static readonly RankedTag[] Tags = [new("news", 5), new("events", 9), new("blog", 2)];

    [Test]
    public void GetPage_OrdersByCount() =>
        Assert.That(TagRanking.GetPage(Tags, 0, 3).Select(t => t.Text), Is.EqualTo(new[] { "events", "news", "blog" }));

    [Test]
    public void GetTop_TakesMostUsed() =>
        Assert.That(TagRanking.GetTop(Tags, 2).Select(t => t.Text), Is.EqualTo(new[] { "events", "news" }));

    [Test]
    public void GetTop_BreaksTiesByText() =>
        Assert.That(TagRanking.GetTop([new("b", 5), new("A", 5), new("c", 9)], 2).Select(t => t.Text), Is.EqualTo(new[] { "c", "A" }));

    [Test]
    public void GetTop_MoreThanThereAreReturnsAll() =>
        Assert.That(TagRanking.GetTop(Tags, 10), Has.Count.EqualTo(3));

    [Test]
    public void GetTop_ZeroIsEmpty() =>
        Assert.That(TagRanking.GetTop(Tags, 0), Is.Empty);

    [Test]
    public void GetTop_NegativeThrows() =>
        Assert.Throws<ArgumentOutOfRangeException>(() => TagRanking.GetTop(Tags, -1));

    [Test]
    public void GetTop_NullThrows() =>
        Assert.Throws<ArgumentNullException>(() => TagRanking.GetTop(null!, 1));
}
CS

# git can't run inside the eval sandbox, so hand the reviewer the diff as a file.
git add -A && git diff --cached > CHANGE.diff && git reset -q
