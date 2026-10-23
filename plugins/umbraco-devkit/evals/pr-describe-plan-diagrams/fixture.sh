#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`, and a
branch named after the slug.
EOF
mkdir -p src/Umbraco.Community.TagCloud/Services docs/plans/tag-filters
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

1. [x] [BRIEF.md](./BRIEF.md) — editors can hide tags from the cloud
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — a filter list in settings, applied in TagCloudService
3. [x] [SPEC.md](./SPEC.md) — exclude by exact name or prefix, case-insensitive
4. [x] [STORIES.md](./STORIES.md) — two stories
5. [x] [PLAN.md](./PLAN.md) — three tasks
6. [x] [BUILD-LOG.md](./BUILD-LOG.md) — three tasks, three commits

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
EOF
cat > docs/plans/tag-filters/BRIEF.md <<'EOF'
# Tag filters: brief

Editors can't keep internal tags ("draft", "internal-*") out of the public tag cloud.
EOF
cat > docs/plans/tag-filters/ARCHITECTURE.md <<'EOF'
# Tag filters: architecture

- `TagFilterOptions` bound from `TagCloud:Filters`: exact names and prefixes.
- `TagFilter` applies the options; `TagCloudService` calls it before ordering.
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

- [x] Add `TagFilterOptions` and bind it from `TagCloud:Filters`.
- [x] Add `TagFilter` with exact-name and prefix rules.
- [x] Call `TagFilter` from `TagCloudService` before ordering.
EOF
cat > docs/plans/tag-filters/DECISION-LOG.md <<'EOF'
# Tag filters: decision log

- 2026-10-02 (feature-design): Filters live in appsettings.json, not in the database. The
  user chose this so filters deploy with the site.
- 2026-10-09 (feature-build, task 2): Leading and trailing spaces are trimmed from configured
  names and prefixes. The spec didn't say; untrimmed values from appsettings never match.
EOF
cat > docs/plans/tag-filters/BUILD-LOG.md <<'EOF'
# Tag filters: build log

- Task 1 — `a1b2c3d` — options bind from `TagCloud:Filters`; unit test.
- Task 2 — `d4e5f6a` — exact-name and prefix rules; unit tests for both.
- Task 3 — `b7c8d9e` — TagCloudService filters before ordering; test through GetCloud.
EOF
mkdir -p docs/plans/tag-filters/diagrams
cat >> docs/plans/tag-filters/ARCHITECTURE.md <<'EOF'

![Where the filter runs](./diagrams/tag-filter-flow.svg)
EOF
cat > docs/plans/tag-filters/diagrams/tag-filter-flow.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="960" height="200" viewBox="0 0 960 200">
  <style id="theme"><![CDATA[
svg { --bg: #ffffff; --text: #0f172a; --edge: #334155; --node-fill: #f8fafc; --node-stroke: #475569; }
@media (prefers-color-scheme: dark) { svg { --bg: #1f1f1f; --text: #e0e0e0; --edge: #a0a0a0; --node-fill: #2b2b2b; --node-stroke: #6b6b6b; } }
svg { font-family: system-ui, sans-serif; font-size: 13px; }
.bg { fill: var(--bg); }
.node .shape { fill: var(--node-fill); stroke: var(--node-stroke); }
.node .title { fill: var(--text); font-weight: 600; text-anchor: middle; }
.edge { fill: none; stroke: var(--edge); stroke-width: 1.5px; }
.arrowhead { fill: var(--edge); }
]]></style>
  <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse"><path class="arrowhead" d="M0,0 L10,5 L0,10 z"/></marker></defs>
  <rect class="bg" width="960" height="200"/>
  <g class="node"><rect class="shape" x="40" y="74" width="220" height="52" rx="6"/><text class="title" x="150" y="105">ITagService</text></g>
  <g class="node"><rect class="shape" x="370" y="74" width="220" height="52" rx="6"/><text class="title" x="480" y="105">TagFilter.IsHidden</text></g>
  <g class="node"><rect class="shape" x="700" y="74" width="220" height="52" rx="6"/><text class="title" x="810" y="105">TagCloudService.GetCloud</text></g>
  <path class="edge" d="M260,100 H370" marker-end="url(#arrow)"/>
  <path class="edge" d="M590,100 H700" marker-end="url(#arrow)"/>
</svg>
EOF
git add -A && git commit -qm "docs: add plan folder for tag-filters"

# ---- the feature branch's changes ----
cat > src/Umbraco.Community.TagCloud/TagFilterOptions.cs <<'EOF'
namespace Umbraco.Community.TagCloud;

public class TagFilterOptions
{
    public List<string> Names { get; set; } = [];
    public List<string> Prefixes { get; set; } = [];
}
EOF
cat > src/Umbraco.Community.TagCloud/Services/TagFilter.cs <<'EOF'
using Microsoft.Extensions.Options;

namespace Umbraco.Community.TagCloud.Services;

public class TagFilter(IOptions<TagFilterOptions> options)
{
    private readonly HashSet<string> _names =
        options.Value.Names.Select(n => n.Trim()).ToHashSet(StringComparer.OrdinalIgnoreCase);

    private readonly string[] _prefixes = options.Value.Prefixes.Select(p => p.Trim()).ToArray();

    public bool IsHidden(string text) =>
        _names.Contains(text) || _prefixes.Any(p => text.StartsWith(p, StringComparison.Ordinal));
}
EOF
cat > src/Umbraco.Community.TagCloud/Services/TagCloudService.cs <<'EOF'
using Umbraco.Cms.Core.Services;

namespace Umbraco.Community.TagCloud.Services;

public class TagCloudService(ITagService tagService, TagFilter filter)
{
    public IReadOnlyList<(string Text, int Weight)> GetCloud(string group) =>
        tagService.GetAllContentTags(group)
            .Where(t => !filter.IsHidden(t.Text))
            .OrderByDescending(t => t.NodeCount)
            .Select(t => (t.Text, t.NodeCount))
            .ToList();
}
EOF
# git can't run inside the eval sandbox, so hand over the branch diff as a file.
git add -A && git diff --cached > CHANGE.diff && git reset -q --hard
cat > COMMITS.txt <<'EOF'
b7c8d9e feat(tag-filters): filter the cloud before ordering
d4e5f6a feat(tag-filters): add exact-name and prefix rules
a1b2c3d feat(tag-filters): bind TagFilterOptions from TagCloud:Filters
EOF
