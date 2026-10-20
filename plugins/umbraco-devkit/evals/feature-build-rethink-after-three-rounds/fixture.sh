#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
EOF
mkdir -p src/Umbraco.Community.TagCloud/Services docs/plans/tag-filters
cat > src/Umbraco.Community.TagCloud/Umbraco.Community.TagCloud.csproj <<'EOF'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup><TargetFramework>net10.0</TargetFramework></PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" Version="[17.0.0, 18.0.0)" />
  </ItemGroup>
</Project>
EOF
cat > src/Umbraco.Community.TagCloud/Services/TagCloudService.cs <<'EOF'
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
EOF
cat > docs/plans/tag-filters/README.md <<'EOF'
# Tag filters

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — editors can hide tags from the cloud
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — a filter list stored in settings, applied in TagCloudService
3. [x] [SPEC.md](./SPEC.md) — exclude by exact name or prefix, case-insensitive
4. [x] [STORIES.md](./STORIES.md) — two stories
5. [x] [PLAN.md](./PLAN.md) — three tasks
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
EOF
cat > docs/plans/tag-filters/BRIEF.md <<'EOF'
# Tag filters: brief

## Problem
Editors can't keep internal tags ("draft", "internal-*") out of the public tag cloud.

## Success
No internal tag shows in the cloud once it's on the filter list.
EOF
cat > docs/plans/tag-filters/ARCHITECTURE.md <<'EOF'
# Tag filters: architecture

- `TagFilterOptions` bound from `TagCloud:Filters` in appsettings.json: a list of exact names
  and a list of prefixes.
- `TagFilter` applies the options; `TagCloudService` calls it before ordering.
- No database change.
EOF
cat > docs/plans/tag-filters/SPEC.md <<'EOF'
# Tag filters: spec

- A tag whose text equals an exact name, ignoring case, is left out.
- A tag whose text starts with a prefix, ignoring case, is left out.
- With no filters configured, the cloud is unchanged.
EOF
cat > docs/plans/tag-filters/STORIES.md <<'EOF'
# Tag filters: stories

1. As an editor, I can list tag names to hide, so drafts never show publicly.
2. As an editor, I can hide every tag with a prefix, so a family of internal tags stays out.
EOF
cat > docs/plans/tag-filters/PLAN.md <<'EOF'
# Tag filters: plan

- [x] Add `TagFilterOptions` and bind it from `TagCloud:Filters`.
- [ ] Add `TagFilter` with exact-name and prefix rules, with unit tests.
- [ ] Call `TagFilter` from `TagCloudService` before ordering, with a test that filtered tags never appear.
EOF
cat > docs/plans/tag-filters/DECISION-LOG.md <<'EOF'
# Tag filters: decision log
EOF
cat > docs/plans/tag-filters/BUILD-LOG.md <<'EOF'
# Tag filters: build log

Branch `tag-filters`, worktree `../tag-filters`.

- Task 1: `TagFilterOptions` bound from `TagCloud:Filters`. Reviewer PASS on round 1. `a1c9e02`.
EOF
mkdir -p src/Umbraco.Community.TagCloud/Filters review-rounds
cat > src/Umbraco.Community.TagCloud/Filters/TagFilterOptions.cs <<'EOF'
namespace Umbraco.Community.TagCloud.Filters;

public class TagFilterOptions
{
    public const string Section = "TagCloud:Filters";

    public List<string> Names { get; set; } = [];

    public List<string> Prefixes { get; set; } = [];
}
EOF
cat > src/Umbraco.Community.TagCloud/Filters/TagFilter.cs <<'EOF'
using System.Text.RegularExpressions;
using Microsoft.Extensions.Options;

namespace Umbraco.Community.TagCloud.Filters;

public class TagFilter(IOptions<TagFilterOptions> options)
{
    public bool IsHidden(string tag)
    {
        var o = options.Value;
        if (o.Names.Any(n => string.Equals(n, tag, StringComparison.OrdinalIgnoreCase)))
        {
            return true;
        }

        if (o.Prefixes.Count == 0)
        {
            return false;
        }

        var pattern = "^(" + string.Join("|", o.Prefixes.Select(Regex.Escape)) + ")";
        return Regex.IsMatch(tag, pattern, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
    }
}
EOF
cat > review-rounds/round-1.md <<'EOF'
# Task 2, review round 1: FAIL

- **Important.** `TagFilter.cs`: prefixes go into the regex unescaped, so a prefix such as
  `c++` or `v1.` throws or matches the wrong tags. Escape each prefix.
EOF
cat > review-rounds/round-2.md <<'EOF'
# Task 2, review round 2: FAIL

- Round 1's finding: fixed.
- **Important.** `TagFilter.cs`: the regex is case-sensitive, but SPEC.md says prefixes
  ignore case. "Internal-HR" isn't hidden by `internal-`.
EOF
cat > review-rounds/round-3.md <<'EOF'
# Task 2, review round 3: FAIL

- Round 2's finding: fixed.
- **Important.** `TagFilter.cs`: `IsHidden` builds and parses a new regex on every call. It
  runs for every tag on every tag-cloud render, a per-request path.
EOF
