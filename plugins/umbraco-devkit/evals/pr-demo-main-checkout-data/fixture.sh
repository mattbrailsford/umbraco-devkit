#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'MD'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Build & test

- `dotnet test` runs the unit tests.
- Start the demo site with `dotnet run --project demo/TagCloud.Demo`. Its port comes from
  `git wdp-port`. The backoffice login is in `demo/TagCloud.Demo/appsettings.Development.json`
  under `Umbraco:CMS:Unattended`.
- The demo site's content (a home page, a blog with tagged posts) lives in its SQLite database.
MD
mkdir -p src/Umbraco.Community.TagCloud/Services src/Umbraco.Community.TagCloud/Migrations
mkdir -p demo/TagCloud.Demo/umbraco/Data demo/TagCloud.Demo/Properties
cat > demo/TagCloud.Demo/TagCloud.Demo.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms" Version="17.2.0" />
    <PackageReference Include="Umbraco.Community.WorktreeDevPort" Version="1.0.0" />
    <ProjectReference Include="../../src/Umbraco.Community.TagCloud/Umbraco.Community.TagCloud.csproj" />
  </ItemGroup>
</Project>
XML
cat > demo/TagCloud.Demo/appsettings.json <<'JSON'
{
  "ConnectionStrings": {
    "umbracoDbDSN": "Data Source=|DataDirectory|/Umbraco.sqlite.db;Cache=Shared;Foreign Keys=True;Pooling=True",
    "umbracoDbDSN_ProviderName": "Microsoft.Data.Sqlite"
  }
}
JSON
cat > demo/TagCloud.Demo/appsettings.Development.json <<'JSON'
{
  "Umbraco": {
    "CMS": {
      "Unattended": {
        "InstallUnattended": true,
        "UnattendedUserName": "Demo",
        "UnattendedUserEmail": "demo@example.com",
        "UnattendedUserPassword": "see-1password"
      }
    }
  }
}
JSON
printf 'SQLite format 3\0' > demo/TagCloud.Demo/umbraco/Data/Umbraco.sqlite.db
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
git add -A && git commit -qm "chore: initial"

# ---- the tag-filters branch's changes ----
cat > src/Umbraco.Community.TagCloud/Migrations/AddTagFilterTable.cs <<'CS'
using Umbraco.Cms.Infrastructure.Migrations;

namespace Umbraco.Community.TagCloud.Migrations;

public class AddTagFilterTable(IMigrationContext context) : AsyncMigrationBase(context)
{
    protected override Task MigrateAsync()
    {
        if (!TableExists("tagCloudFilter"))
        {
            Create.Table<TagFilterDto>().Do();
        }
        return Task.CompletedTask;
    }
}
CS
cat > src/Umbraco.Community.TagCloud/Migrations/TagCloudMigrationPlan.cs <<'CS'
using Umbraco.Cms.Core.Packaging;

namespace Umbraco.Community.TagCloud.Migrations;

public class TagCloudMigrationPlan : PackageMigrationPlan
{
    public TagCloudMigrationPlan() : base("Umbraco.Community.TagCloud") { }

    protected override void DefinePlan() =>
        To<AddTagFilterTable>("tag-cloud-filter-table");
}
CS
cat > src/Umbraco.Community.TagCloud/Services/TagCloudService.cs <<'CS'
using Umbraco.Cms.Core.Services;

namespace Umbraco.Community.TagCloud.Services;

public class TagCloudService(ITagService tagService, ITagFilterRepository filters)
{
    public IReadOnlyList<(string Text, int Weight)> GetCloud(string group) =>
        tagService.GetAllContentTags(group)
            .Where(t => !filters.IsHidden(t.Text))
            .OrderByDescending(t => t.NodeCount)
            .Select(t => (t.Text, t.NodeCount))
            .ToList();
}
CS
# git can't run inside the eval sandbox, so hand over the branch diff and worktree list as files.
git add -A && git diff --cached > CHANGE.diff && git reset -q --hard
git checkout -q -b tag-filters
echo "$(pwd)  0a1b2c3 [tag-filters]" > WORKTREES.txt
