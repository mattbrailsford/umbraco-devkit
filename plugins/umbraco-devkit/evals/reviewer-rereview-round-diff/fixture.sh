#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'MD'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Build & test

`dotnet build` and `dotnet test` from the repo root.
MD
mkdir -p src/Umbraco.Community.TagCloud/Filters tests/Umbraco.Community.TagCloud.Tests docs/plans/tag-filters
cat > src/Umbraco.Community.TagCloud/Umbraco.Community.TagCloud.csproj <<'CS'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup><TargetFramework>net10.0</TargetFramework><Nullable>enable</Nullable></PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" Version="[17.0.0, 18.0.0)" />
  </ItemGroup>
</Project>
CS
cat > src/Umbraco.Community.TagCloud/Filters/TagFilterOptions.cs <<'CS'
namespace Umbraco.Community.TagCloud.Filters;

public class TagFilterOptions
{
    public const string Section = "TagCloud:Filters";

    public List<string> Names { get; set; } = [];

    public List<string> Prefixes { get; set; } = [];
}
CS
cat > src/Umbraco.Community.TagCloud/TagCloudComposer.cs <<'CS'
using Umbraco.Cms.Core.Composing;
using Umbraco.Cms.Core.DependencyInjection;
using Umbraco.Community.TagCloud.Filters;
using Umbraco.Community.TagCloud.Services;

namespace Umbraco.Community.TagCloud;

public class TagCloudComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder)
    {
        builder.Services.Configure<TagFilterOptions>(builder.Config.GetSection(TagFilterOptions.Section));
        builder.Services.AddSingleton<TagCloudService>();
    }
}
CS
cat > docs/plans/tag-filters/SPEC.md <<'MD'
# Tag filters: spec

- A tag whose text equals an exact name, ignoring case, is left out.
- A tag whose text starts with a prefix, ignoring case, is left out.
- With no filters configured, the cloud is unchanged.
MD
cat > docs/plans/tag-filters/PLAN.md <<'MD'
# Tag filters: plan

- [x] Add `TagFilterOptions` and bind it from `TagCloud:Filters`.
- [ ] Add `TagFilter` with exact-name and prefix rules, with unit tests.
- [ ] Call `TagFilter` from `TagCloudService` before ordering, with a test that filtered tags never appear.
MD
mkdir -p src/Umbraco.Community.TagCloud/Services
cat > src/Umbraco.Community.TagCloud/Services/TagCloudService.cs <<'CS'
using Umbraco.Cms.Core.Services;

namespace Umbraco.Community.TagCloud.Services;

public class TagCloudService(ITagService tagService)
{
    public IReadOnlyList<(string Text, int Weight)> GetCloud(string group) =>
        tagService.GetAllContentTags(group)
            .OrderByDescending(t => t.NodeCount)
            .Select(t => (t.Text, t.NodeCount))
            .ToList();
}
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
git add -A && git commit -q -m "feat(filters): bind tag filter options"

# Round 1: the builder's first attempt at task 2.
cat > src/Umbraco.Community.TagCloud/Filters/TagFilter.cs <<'CS'
using Microsoft.Extensions.Options;

namespace Umbraco.Community.TagCloud.Filters;

public class TagFilter(IOptions<TagFilterOptions> options)
{
    private readonly TagFilterOptions _options = options.Value;

    public bool IsHidden(string tag) =>
        _options.Names.Any(n => string.Equals(n, tag, StringComparison.OrdinalIgnoreCase))
        || _options.Prefixes.Any(p => tag.StartsWith(p));

    public string Describe() =>
        $"{_options.Names.Count} names, {_options.Prefixes.Count} prefixes";
}
CS
cat > src/Umbraco.Community.TagCloud/TagCloudComposer.cs <<'CS'
using Umbraco.Cms.Core.Composing;
using Umbraco.Cms.Core.DependencyInjection;
using Umbraco.Community.TagCloud.Filters;
using Umbraco.Community.TagCloud.Services;

namespace Umbraco.Community.TagCloud;

public class TagCloudComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder)
    {
        builder.Services.Configure<TagFilterOptions>(builder.Config.GetSection(TagFilterOptions.Section));
        builder.Services.AddSingleton<TagFilter>();
        builder.Services.AddSingleton<TagCloudService>();
    }
}
CS
cat > tests/Umbraco.Community.TagCloud.Tests/TagFilterTests.cs <<'CS'
using Microsoft.Extensions.Options;
using NUnit.Framework;
using Umbraco.Community.TagCloud.Filters;

namespace Umbraco.Community.TagCloud.Tests;

public class TagFilterTests
{
    private static TagFilter Create(List<string>? names = null, List<string>? prefixes = null) =>
        new(Options.Create(new TagFilterOptions { Names = names ?? [], Prefixes = prefixes ?? [] }));

    [Test]
    public void Name_IgnoresCase() =>
        Assert.That(Create(names: ["Draft"]).IsHidden("draft"), Is.True);

    [Test]
    public void Prefix_Matches() =>
        Assert.That(Create(prefixes: ["internal-"]).IsHidden("internal-hr"), Is.True);

    [Test]
    public void NoFilters_HidesNothing() =>
        Assert.That(Create().IsHidden("news"), Is.False);
}
CS
cat > REVIEW-ROUND-1.md <<'MD'
# Review, round 1: FAIL

- **Important.** `src/Umbraco.Community.TagCloud/Filters/TagFilter.cs:11`: prefix matching is
  case-sensitive, so "Internal-HR" isn't hidden by the prefix "internal-". SPEC.md says
  prefixes ignore case. Compare with `StringComparison.OrdinalIgnoreCase`, and add a test.
MD
git add -A
round1=$(git write-tree)

# Round 2: the builder's fix for round 1's finding.
sed -i.bak 's/tag.StartsWith(p))/tag.StartsWith(p, StringComparison.OrdinalIgnoreCase))/' \
  src/Umbraco.Community.TagCloud/Filters/TagFilter.cs
rm src/Umbraco.Community.TagCloud/Filters/TagFilter.cs.bak
cat > tests/Umbraco.Community.TagCloud.Tests/TagFilterTests.cs <<'CS'
using Microsoft.Extensions.Options;
using NUnit.Framework;
using Umbraco.Community.TagCloud.Filters;

namespace Umbraco.Community.TagCloud.Tests;

public class TagFilterTests
{
    private static TagFilter Create(List<string>? names = null, List<string>? prefixes = null) =>
        new(Options.Create(new TagFilterOptions { Names = names ?? [], Prefixes = prefixes ?? [] }));

    [Test]
    public void Name_IgnoresCase() =>
        Assert.That(Create(names: ["Draft"]).IsHidden("draft"), Is.True);

    [Test]
    public void Prefix_Matches() =>
        Assert.That(Create(prefixes: ["internal-"]).IsHidden("internal-hr"), Is.True);

    [Test]
    public void Prefix_IgnoresCase() =>
        Assert.That(Create(prefixes: ["internal-"]).IsHidden("Internal-HR"), Is.True);

    [Test]
    public void NoFilters_HidesNothing() =>
        Assert.That(Create().IsHidden("news"), Is.False);
}
CS

# git can't run inside the eval sandbox, so hand the reviewer the diffs as files.
git add -A
git diff --cached "$round1" -- src tests > ROUND-2.diff
git diff --cached HEAD -- src tests > CHANGE.diff
git reset -q
