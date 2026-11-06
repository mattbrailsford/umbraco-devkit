#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Stack

- Umbraco CMS: 17
- Database: SQL Server + SQLite

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
EOF
P=src/Umbraco.Community.TagCloud
mkdir -p $P/Services $P/Filters $P/Persistence docs/plans/tag-filters
cat > $P/Umbraco.Community.TagCloud.csproj <<'EOF'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup><TargetFramework>net10.0</TargetFramework></PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" Version="[17.0.0, 18.0.0)" />
    <PackageReference Include="Umbraco.Cms.Persistence.EFCore" Version="[17.0.0, 18.0.0)" />
  </ItemGroup>
</Project>
EOF
cat > $P/Services/TagCloudService.cs <<'EOF'
using Microsoft.Extensions.Caching.Memory;
using Umbraco.Cms.Core.Services;

namespace Umbraco.Community.TagCloud.Services;

public class TagCloudService(ITagService tagService, IMemoryCache cache)
{
    public const string CacheKey = "TagCloud:";

    public IReadOnlyList<(string Text, int Weight)> GetCloud(string group) =>
        cache.GetOrCreate(CacheKey + group, _ => tagService.GetAllContentTags(group)
            .OrderByDescending(t => t.NodeCount)
            .Select(t => (t.Text, t.NodeCount))
            .ToList())!;
}
EOF
cat > docs/plans/tag-filters/README.md <<'EOF'
# Tag filters

1. [x] [BRIEF.md](./BRIEF.md) — editors can hide tags from the cloud
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — filters in a package table, applied when the cloud is built
3. [x] [SPEC.md](./SPEC.md) — exact names, case-insensitive; the cloud updates on publish
4. [x] [STORIES.md](./STORIES.md) — two stories
5. [x] [PLAN.md](./PLAN.md) — three tasks
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>
EOF
cat > docs/plans/tag-filters/BRIEF.md <<'EOF'
# Tag filters: brief

Editors can't keep internal tags ("draft", "internal") out of the public tag cloud.
EOF
cat > docs/plans/tag-filters/ARCHITECTURE.md <<'EOF'
# Tag filters: architecture

- Hidden tag names live in a package table, `tagCloudHiddenTag`, through EF Core
  (`TagCloudDbContext`), with migrations for SQL Server and SQLite.
- `HiddenTagRepository` reads and writes them.
- A `ContentPublishedNotification` handler clears the cached cloud for each tag group on a
  published item, and drops hidden tags when the cloud is rebuilt.
EOF
cat > docs/plans/tag-filters/SPEC.md <<'EOF'
# Tag filters: spec

- A tag whose text equals a hidden name, ignoring case, never shows in the cloud.
- Publishing an item updates the cloud for its tag groups within the same request.
EOF
cat > docs/plans/tag-filters/STORIES.md <<'EOF'
# Tag filters: stories

1. As an editor, I can list tag names to hide, so drafts never show publicly.
2. As an editor, publishing a page updates the cloud straight away.
EOF
cat > docs/plans/tag-filters/PLAN.md <<'EOF'
# Tag filters: plan

## Data

- [x] **T1** - story: 1. Add `TagCloudDbContext` and register it.
  Acceptance: the site starts with the context registered.
  depends-on: none

- [ ] **T2** - story: 1, 2. Add the `tagCloudHiddenTag` table with migrations for SQL Server
  and SQLite, `HiddenTagRepository`, and a `ContentPublishedNotification` handler that loads
  the hidden names and clears the cached cloud for each tag group on every published item.
  Acceptance: specs `HiddenTags.feature` go green; publishing an item updates its cloud.
  depends-on: T1

## Wire

- [ ] **T3** - **wire: hidden tags into TagCloudService.** story: 1. Drop hidden names when
  the cloud is built. Acceptance: a real request to the cloud leaves hidden tags out.
  depends-on: T2
EOF
cat > docs/plans/tag-filters/DECISION-LOG.md <<'EOF'
# Tag filters: decision log
EOF
cat > docs/plans/tag-filters/BUILD-LOG.md <<'EOF'
# Tag filters: build log

Branch `tag-filters`, worktree `../tag-filters`.

- T1: `TagCloudDbContext` registered. Reviewer PASS on round 1. `a1c9e02`.
EOF
mkdir -p $P/Persistence/Migrations $P/Notifications agent-notes
cat > $P/Notifications/TagCloudPublishedHandler.cs <<'X'
using Microsoft.Extensions.Caching.Memory;
using Umbraco.Cms.Core.Events;
using Umbraco.Cms.Core.Notifications;
using Umbraco.Community.TagCloud.Persistence;
using Umbraco.Community.TagCloud.Services;

namespace Umbraco.Community.TagCloud.Notifications;

internal sealed class TagCloudPublishedHandler(HiddenTagRepository hidden, IMemoryCache cache)
    : INotificationAsyncHandler<ContentPublishedNotification>
{
    public async Task HandleAsync(ContentPublishedNotification notification, CancellationToken cancellationToken)
    {
        foreach (var content in notification.PublishedEntities)
        {
            var names = await hidden.GetAllAsync(cancellationToken);
            foreach (var group in content.Properties.Where(p => p.PropertyType.PropertyEditorAlias == "Umbraco.Tags").Select(p => p.Alias))
            {
                cache.Remove(TagCloudService.CacheKey + group);
            }
        }
    }
}
X
cat > agent-notes/t2-review-dispatch.md <<'X'
# Prompt sent to the reviewer for T2

Review the diff for T2 in tag-filters (task text below). Load these skills before you start:
`umbraco-package-conventions`, `ef-core-data`, `umbraco-performance`,
`umbraco-extensibility`. Start your report with the skills you loaded.

T2: Add the `tagCloudHiddenTag` table with migrations for SQL Server and SQLite,
`HiddenTagRepository`, and a `ContentPublishedNotification` handler that loads the hidden
names and clears the cached cloud for each tag group on every published item.
X
cat > agent-notes/t2-review-report.md <<'X'
# Reviewer report: T2

Skills loaded: `umbraco-package-conventions`.

Build and tests: green (`dotnet build`, `dotnet test`, 14 passed).

- Naming and visibility follow the package conventions: `HiddenTagRepository` and the handler
  are internal, async methods end in `Async`.
- The handler is registered in `TagCloudComposer`.
- Migrations exist for both providers.

Verdict: **PASS**
X
