#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
MD
mkdir -p src/Umbraco.Community.TagCloud/Services docs/plans/tag-filters
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
cat > docs/plans/tag-filters/README.md <<'MD'
# Tag filters

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — editors can hide tags from the cloud
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — a filter list stored in settings, applied in TagCloudService
3. [x] [SPEC.md](./SPEC.md) — exclude by exact name or prefix, case-insensitive
4. [ ] [STORIES.md](./STORIES.md) — <pending>
5. [ ] [PLAN.md](./PLAN.md) — <pending>
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
MD
cat > docs/plans/tag-filters/BRIEF.md <<'MD'
# Tag filters: brief

## Problem
Editors can't keep internal tags ("draft", "internal-*") out of the public tag cloud.

> [!IMPORTANT]
> Filtering must not change which tags are stored, only which are shown.

## Success
No internal tag shows in the cloud once it's on the filter list.
MD
cat > docs/plans/tag-filters/ARCHITECTURE.md <<'MD'
# Tag filters: architecture

- `TagFilterOptions` bound from `TagCloud:Filters` in appsettings.json: a list of exact names
  and a list of prefixes.
- `TagFilter` applies the options; `TagCloudService` calls it before ordering.
- No database change. No backoffice UI.
MD
cat > docs/plans/tag-filters/SPEC.md <<'MD'
# Tag filters: spec

- A tag whose text equals an exact name, ignoring case, is left out.
- A tag whose text starts with a prefix, ignoring case, is left out.
- With no filters configured, the cloud is unchanged.

## Management API surface
None.

## Frontend components
None.
MD
cat > docs/plans/tag-filters/DECISION-LOG.md <<'MD'
# Tag filters: decision log
MD
git init -q -b main
mkdir -p .git/markdown-preview
cat > .git/markdown-preview/comments.json <<'JSON'
[{"id": "c1", "path": "/docs/plans/tag-filters/SPEC.md", "quote": "With no filters configured, the cloud is unchanged.", "prefix": "", "suffix": "", "section": "",
  "body": "Say what happens when a configured prefix is empty: ignore it, or hide every tag?", "status": "deferred", "owner": "feature-design",
  "replies": [{"author": "claude", "body": "Left for feature-design.", "created": "2026-10-24T10:05:00"}], "created": "2026-10-24T10:00:00"}]
JSON
