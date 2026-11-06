#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'MD'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Build & test

- Build: `dotnet build TagCloud.slnx`
- Test: `dotnet test TagCloud.slnx`. The integration tests boot Umbraco on SQL Server
  LocalDB and take about 12 minutes; the unit tests take seconds.
- Acceptance: `npx playwright test` in `tests/Umbraco.Community.TagCloud.Tests.Acceptance`,
  against the demo site on https://localhost:44331 (about 15 minutes for the whole suite).
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

# Task 2, already reviewed and committed.
cat > src/Umbraco.Community.TagCloud/Filters/TagFilter.cs <<'CS'
using Microsoft.Extensions.Options;

namespace Umbraco.Community.TagCloud.Filters;

public class TagFilter(IOptions<TagFilterOptions> options)
{
    private readonly TagFilterOptions _options = options.Value;

    public bool IsHidden(string tag) =>
        _options.Names.Any(n => string.Equals(n, tag, StringComparison.OrdinalIgnoreCase))
        || _options.Prefixes.Any(p => tag.StartsWith(p, StringComparison.OrdinalIgnoreCase));
}
CS
sed -i.bak 's/        builder.Services.AddSingleton<TagCloudService>();/        builder.Services.AddSingleton<TagFilter>();\n        builder.Services.AddSingleton<TagCloudService>();/' \
  src/Umbraco.Community.TagCloud/TagCloudComposer.cs
rm src/Umbraco.Community.TagCloud/TagCloudComposer.cs.bak
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
sed -i.bak 's/- \[ \] Add `TagFilter`/- [x] Add `TagFilter`/' docs/plans/tag-filters/PLAN.md
rm docs/plans/tag-filters/PLAN.md.bak
git add -A && git commit -q -m "feat(filters): add TagFilter with name and prefix rules"

# The rest of the solution: integration and acceptance tests, plus a demo site.
mkdir -p tests/Umbraco.Community.TagCloud.Tests.Integration tests/Umbraco.Community.TagCloud.Tests.Acceptance/tests demo/TagCloud.DemoSite
cat > tests/Umbraco.Community.TagCloud.Tests.Integration/Umbraco.Community.TagCloud.Tests.Integration.csproj <<'CS'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup><TargetFramework>net10.0</TargetFramework><Nullable>enable</Nullable></PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Tests.Integration" Version="[17.0.0, 18.0.0)" />
    <PackageReference Include="NUnit3TestAdapter" Version="5.0.0" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="../../src/Umbraco.Community.TagCloud/Umbraco.Community.TagCloud.csproj" />
  </ItemGroup>
</Project>
CS
cat > tests/Umbraco.Community.TagCloud.Tests.Integration/TagCloudComposerTests.cs <<'CS'
using NUnit.Framework;
using Umbraco.Cms.Tests.Common.Testing;
using Umbraco.Cms.Tests.Integration.Testing;

namespace Umbraco.Community.TagCloud.Tests.Integration;

[UmbracoTest(Database = UmbracoTestOptions.Database.NewSchemaPerFixture)]
public class TagCloudComposerTests : UmbracoIntegrationTest
{
    [Test]
    public void Composer_RegistersTheCloud() =>
        Assert.That(GetRequiredService<Services.TagCloudService>(), Is.Not.Null);
}
CS
cat > tests/Umbraco.Community.TagCloud.Tests.Acceptance/package.json <<'JSON'
{ "name": "tagcloud-acceptance", "private": true, "devDependencies": { "@playwright/test": "1.55.0" } }
JSON
cat > tests/Umbraco.Community.TagCloud.Tests.Acceptance/tests/cloud.spec.ts <<'TS'
import { test, expect } from '@playwright/test';

test('the cloud renders on the home page', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('.tag-cloud a').first()).toBeVisible();
});
TS
cat > demo/TagCloud.DemoSite/TagCloud.DemoSite.csproj <<'CS'
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup><TargetFramework>net10.0</TargetFramework></PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms" Version="[17.0.0, 18.0.0)" />
    <ProjectReference Include="../../src/Umbraco.Community.TagCloud/Umbraco.Community.TagCloud.csproj" />
  </ItemGroup>
</Project>
CS
cat > TagCloud.slnx <<'XML'
<Solution>
  <Project Path="src/Umbraco.Community.TagCloud/Umbraco.Community.TagCloud.csproj" />
  <Project Path="tests/Umbraco.Community.TagCloud.Tests/Umbraco.Community.TagCloud.Tests.csproj" />
  <Project Path="tests/Umbraco.Community.TagCloud.Tests.Integration/Umbraco.Community.TagCloud.Tests.Integration.csproj" />
  <Project Path="demo/TagCloud.DemoSite/TagCloud.DemoSite.csproj" />
</Solution>
XML
git add -A && git commit -q -m "test: add integration and acceptance projects"
