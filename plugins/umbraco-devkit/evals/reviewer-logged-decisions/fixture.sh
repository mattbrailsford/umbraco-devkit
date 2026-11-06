#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Build & test

`dotnet build` and `dotnet test` from the repo root.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`, and a
branch named after the slug.
EOF
mkdir -p src/Umbraco.Community.TagCloud/Services tests/Umbraco.Community.TagCloud.Tests \
  docs/plans/tag-filters
cat > src/Umbraco.Community.TagCloud/Umbraco.Community.TagCloud.csproj <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Core" Version="17.0.0" />
    <InternalsVisibleTo Include="Umbraco.Community.TagCloud.Tests" />
  </ItemGroup>
</Project>
EOF
cat > tests/Umbraco.Community.TagCloud.Tests/Umbraco.Community.TagCloud.Tests.csproj <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageReference Include="Microsoft.Extensions.Configuration.Binder" Version="10.0.0" />
    <PackageReference Include="Moq" Version="4.20.72" />
    <PackageReference Include="NUnit" Version="4.3.2" />
    <PackageReference Include="NUnit3TestAdapter" Version="5.0.0" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\Umbraco.Community.TagCloud\Umbraco.Community.TagCloud.csproj" />
  </ItemGroup>
</Project>
EOF
cat > src/Umbraco.Community.TagCloud/Services/TagCloudService.cs <<'EOF'
using Umbraco.Cms.Core.Services;

namespace Umbraco.Community.TagCloud.Services;

internal class TagCloudService(ITagService tagService)
{
    public IReadOnlyList<(string Text, int Weight)> GetCloud(string group) =>
        tagService.GetAllContentTags(group)
            .OrderByDescending(t => t.NodeCount)
            .Select(t => (t.Text, t.NodeCount))
            .ToList();
}
EOF
cat > src/Umbraco.Community.TagCloud/TagCloudComposer.cs <<'EOF'
using Umbraco.Cms.Core.Composing;
using Umbraco.Cms.Core.DependencyInjection;
using Umbraco.Community.TagCloud.Services;

namespace Umbraco.Community.TagCloud;

public class TagCloudComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder)
    {
        builder.Services.AddScoped<TagCloudService>();
    }
}
EOF
cat > docs/plans/tag-filters/README.md <<'EOF'
# Tag filters

1. [x] [BRIEF.md](./BRIEF.md) — editors can hide tags from the cloud
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — a filter list in settings, applied by a TagFilter
3. [x] [SPEC.md](./SPEC.md) — exclude by exact name or prefix, case-insensitive
4. [x] [STORIES.md](./STORIES.md) — two stories
5. [x] [PLAN.md](./PLAN.md) — three tasks

What was built: [BUILD-LOG.md](./BUILD-LOG.md) · Why things changed: [DECISION-LOG.md](./DECISION-LOG.md)
EOF
cat > docs/plans/tag-filters/BRIEF.md <<'EOF'
# Tag filters: brief

Editors can't keep internal tags ("draft", "internal-*") out of the public tag cloud.
EOF
cat > docs/plans/tag-filters/ARCHITECTURE.md <<'EOF'
# Tag filters: architecture

- `TagFilterOptions` bound from the `TagCloud:Filters` section of appsettings.json: exact
  names and prefixes.
- `TagFilter`, a singleton, applies the options. `TagCloudService` calls it before ordering.
EOF
cat > docs/plans/tag-filters/SPEC.md <<'EOF'
# Tag filters: spec

- A tag whose text equals an exact name, ignoring case, is left out.
- A tag whose text starts with a prefix, ignoring case, is left out.
- With no filters configured, the cloud is unchanged.

## Management API surface
None.

## Frontend components
None.
EOF
cat > docs/plans/tag-filters/STORIES.md <<'EOF'
# Tag filters: stories

1. Hide tags by name. 2. Hide tags by prefix.
EOF
cat > docs/plans/tag-filters/PLAN.md <<'EOF'
# Tag filters: plan

- [x] T1. Add `TagFilterOptions` and bind it from `TagCloud:Filters`.
- [x] T2. Add `TagFilter` with exact-name and prefix rules.
- [x] T3. Call `TagFilter` from `TagCloudService` before ordering.
EOF
cat > docs/plans/tag-filters/DECISION-LOG.md <<'EOF'
# Tag filters: decision log

- 2026-10-02 (feature-design): Filters live in appsettings.json, not in the database, so
  they deploy with the site.
- 2026-10-08 (feature-build, task 1, user): Options bind from `Umbraco:TagCloud:Filters`, not
  `TagCloud:Filters`. Asked during task 1; the user wants the package's settings under the
  `Umbraco` section with the CMS's own.
- 2026-10-09 (feature-build, task 2, agent): No separate `TagFilter` class. The two rules
  are a private method on `TagCloudService`, the only caller; a class and a registration for
  two lines bought nothing.
EOF
cat > docs/plans/tag-filters/BUILD-LOG.md <<'EOF'
# Tag filters: build log

- Task 1 — `a1b2c3d` — options bind from `Umbraco:TagCloud:Filters`; unit test.
- Task 2 — `d4e5f6a` — exact-name and prefix rules; unit tests for both, case-insensitive.
- Task 3 — `b7c8d9e` — GetCloud filters before ordering; test through GetCloud.
EOF
git add -A && git commit -qm "docs: add plan folder for tag-filters"

# ---- the feature branch's changes ----
cat > src/Umbraco.Community.TagCloud/TagFilterOptions.cs <<'EOF'
namespace Umbraco.Community.TagCloud;

public class TagFilterOptions
{
    public const string Section = "Umbraco:TagCloud:Filters";

    public List<string> Names { get; set; } = [];
    public List<string> Prefixes { get; set; } = [];
}
EOF
cat > src/Umbraco.Community.TagCloud/TagCloudComposer.cs <<'EOF'
using Microsoft.Extensions.DependencyInjection;
using Umbraco.Cms.Core.Composing;
using Umbraco.Cms.Core.DependencyInjection;
using Umbraco.Community.TagCloud.Services;

namespace Umbraco.Community.TagCloud;

public class TagCloudComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder)
    {
        builder.Services.Configure<TagFilterOptions>(
            builder.Config.GetSection(TagFilterOptions.Section));
        builder.Services.AddScoped<TagCloudService>();
    }
}
EOF
cat > src/Umbraco.Community.TagCloud/Services/TagCloudService.cs <<'EOF'
using Microsoft.Extensions.Options;
using Umbraco.Cms.Core.Services;

namespace Umbraco.Community.TagCloud.Services;

internal class TagCloudService(ITagService tagService, IOptions<TagFilterOptions> options)
{
    private readonly HashSet<string> _names =
        options.Value.Names.Select(n => n.Trim()).Where(n => n.Length > 0).ToHashSet(StringComparer.OrdinalIgnoreCase);

    private readonly string[] _prefixes = options.Value.Prefixes.Select(p => p.Trim()).Where(p => p.Length > 0).ToArray();

    public IReadOnlyList<(string Text, int Weight)> GetCloud(string group) =>
        tagService.GetAllContentTags(group)
            .Where(t => !IsHidden(t.Text))
            .OrderByDescending(t => t.NodeCount)
            .Select(t => (t.Text, t.NodeCount))
            .ToList();

    private bool IsHidden(string text) =>
        _names.Contains(text)
        || _prefixes.Any(p => text.StartsWith(p, StringComparison.OrdinalIgnoreCase));
}
EOF
cat > tests/Umbraco.Community.TagCloud.Tests/TagCloudServiceTests.cs <<'EOF'
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using Moq;
using NUnit.Framework;
using Umbraco.Cms.Core.Models;
using Umbraco.Cms.Core.Services;
using Umbraco.Community.TagCloud.Services;

namespace Umbraco.Community.TagCloud.Tests;

public class TagCloudServiceTests
{
    private static TagCloudService Create(TagFilterOptions filters, params (string Text, int Count)[] tags)
    {
        var tagService = new Mock<ITagService>();
        tagService.Setup(s => s.GetAllContentTags("default", null))
            .Returns(tags.Select(t => (ITag)new Tag { Text = t.Text, NodeCount = t.Count }).ToList());
        return new TagCloudService(tagService.Object, Options.Create(filters));
    }

    [Test]
    public void Binds_filters_from_the_umbraco_section()
    {
        var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Umbraco:TagCloud:Filters:Names:0"] = "draft",
            ["Umbraco:TagCloud:Filters:Prefixes:0"] = "internal-",
        }).Build();

        var bound = config.GetSection(TagFilterOptions.Section).Get<TagFilterOptions>()!;

        Assert.That(bound.Names, Is.EqualTo(new[] { "draft" }));
        Assert.That(bound.Prefixes, Is.EqualTo(new[] { "internal-" }));
    }

    [Test]
    public void Hides_an_exact_name_ignoring_case()
    {
        var service = Create(new() { Names = ["Draft"] }, ("draft", 5), ("news", 3));
        Assert.That(service.GetCloud("default").Select(t => t.Text), Is.EqualTo(new[] { "news" }));
    }

    [Test]
    public void Hides_a_prefix_ignoring_case()
    {
        var service = Create(new() { Prefixes = ["internal-"] }, ("Internal-IT", 4), ("news", 3));
        Assert.That(service.GetCloud("default").Select(t => t.Text), Is.EqualTo(new[] { "news" }));
    }

    [Test]
    public void Leaves_the_cloud_unchanged_with_no_filters()
    {
        var service = Create(new(), ("draft", 5), ("news", 3));
        Assert.That(service.GetCloud("default").Select(t => t.Text), Is.EqualTo(new[] { "draft", "news" }));
    }
}
EOF
# git can't run inside the eval sandbox, so hand over the branch diff as a file.
git add -A && git diff --cached > CHANGE.diff && git reset -q --hard
cat > COMMITS.txt <<'EOF'
b7c8d9e feat(tag-filters): filter the cloud before ordering
d4e5f6a feat(tag-filters): add exact-name and prefix rules
a1b2c3d feat(tag-filters): bind TagFilterOptions from Umbraco:TagCloud:Filters
EOF
