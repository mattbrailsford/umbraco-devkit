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
- The demo site's content lives in its SQLite database. The worktree hook copies it into each
  new worktree.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/` and a worktree named after
the slug under `worktrees/`.
MD
git add -A && git commit -qm "chore: initial"

W=worktrees/tag-filters
mkdir -p $W/src/Umbraco.Community.TagCloud/Services $W/demo/TagCloud.Demo/umbraco/Data
mkdir -p $W/docs/plans/tag-filters
cp CLAUDE.md $W/
cat > $W/demo/TagCloud.Demo/TagCloud.Demo.csproj <<'XML'
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
cat > $W/demo/TagCloud.Demo/appsettings.json <<'JSON'
{
  "ConnectionStrings": {
    "umbracoDbDSN": "Data Source=|DataDirectory|/Umbraco.sqlite.db;Cache=Shared;Foreign Keys=True;Pooling=True",
    "umbracoDbDSN_ProviderName": "Microsoft.Data.Sqlite"
  }
}
JSON
printf 'SQLite format 3\0' > $W/demo/TagCloud.Demo/umbraco/Data/Umbraco.sqlite.db
cat > $W/src/Umbraco.Community.TagCloud/Services/TagFilter.cs <<'CS'
using Microsoft.Extensions.Options;

namespace Umbraco.Community.TagCloud.Services;

public class TagFilter(IOptions<TagFilterOptions> options)
{
    private readonly HashSet<string> _names =
        options.Value.Names.Select(n => n.Trim()).ToHashSet(StringComparer.OrdinalIgnoreCase);

    private readonly string[] _prefixes = options.Value.Prefixes.Select(p => p.Trim()).ToArray();

    public bool IsHidden(string text) =>
        _names.Contains(text) || _prefixes.Any(p => text.StartsWith(p, StringComparison.OrdinalIgnoreCase));
}
CS
cat > $W/docs/plans/tag-filters/SPEC.md <<'MD'
# Tag filters: spec

- A tag whose text equals an exact name, ignoring case, is left out of the cloud.
- A tag whose text starts with a prefix, ignoring case, is left out.
- With no filters configured, the cloud is unchanged.
- Filters are read from `TagCloud:Filters` (`Names`, `Prefixes`) in appsettings.
MD
cat > $W/docs/plans/tag-filters/STORIES.md <<'MD'
# Tag filters: stories

1. As an editor, I can hide a tag by its exact name.
2. As an editor, I can hide every tag that starts with a prefix.
MD
cat > $W/docs/plans/tag-filters/BUILD-LOG.md <<'MD'
# Tag filters: build log

- Task 1 — `a1b2c3d` — options bind from `TagCloud:Filters`; unit test.
- Task 2 — `d4e5f6a` — exact-name and prefix rules; unit tests for both.
- Task 3 — `b7c8d9e` — TagCloudService filters before ordering; checked on the home page's
  tag cloud (Content › Home › view page).
  - Demo setup: three blog posts under Content › Blog, tagged `Draft`, `internal-roadmap`
    and `umbraco`; `TagCloud:Filters` in `appsettings.Development.json` set to
    `"Names": ["draft"], "Prefixes": ["internal-"]`. Only `umbraco` should show.
MD
echo "$(pwd)                        0a1b2c3 [main]" > WORKTREES.txt
echo "$(pwd)/worktrees/tag-filters  9f8e7d6 [tag-filters]" >> WORKTREES.txt
