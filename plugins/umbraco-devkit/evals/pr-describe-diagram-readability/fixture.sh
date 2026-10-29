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
P=src/Umbraco.Community.TagCloud
mkdir -p $P/Services $P/Controllers $P/Models docs/plans/tag-pinning
cat > $P/Models/TagCloudItem.cs <<'EOF'
namespace Umbraco.Community.TagCloud.Models;

public record TagCloudItem(string Text, int Weight);
EOF
cat > $P/Services/TagCloudService.cs <<'EOF'
using Umbraco.Cms.Core.Services;
using Umbraco.Community.TagCloud.Models;

namespace Umbraco.Community.TagCloud.Services;

public class TagCloudService(ITagService tagService)
{
    public IReadOnlyList<TagCloudItem> GetCloud(string group) =>
        tagService.GetAllContentTags(group)
            .OrderByDescending(t => t.NodeCount)
            .Select(t => new TagCloudItem(t.Text, t.NodeCount))
            .ToList();
}
EOF
cat > $P/Controllers/TagCloudController.cs <<'EOF'
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Umbraco.Cms.Api.Management.Controllers;
using Umbraco.Cms.Api.Management.Routing;
using Umbraco.Cms.Web.Common.Authorization;
using Umbraco.Community.TagCloud.Services;

namespace Umbraco.Community.TagCloud.Controllers;

[ApiVersion("1.0")]
[VersionedApiBackOfficeRoute("tag-cloud")]
[ApiExplorerSettings(GroupName = "Tag Cloud")]
[Authorize(Policy = AuthorizationPolicies.SectionAccessContent)]
public class TagCloudController(TagCloudService cloud) : ManagementApiControllerBase
{
    [HttpGet("{group}")]
    public IActionResult Get(string group) => Ok(cloud.GetCloud(group));

    [HttpGet("groups")]
    public IActionResult Groups([FromServices] ITagGroupLister lister) => Ok(lister.List());
}
EOF
cat > docs/plans/tag-pinning/README.md <<'EOF'
# Tag pinning

1. [x] [BRIEF.md](./BRIEF.md) — editors can pin tags to the front of a cloud
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — pins stored per group; the service puts them first
3. [x] [SPEC.md](./SPEC.md) — pin, unpin, and pinned tags flagged in the cloud
4. [x] [STORIES.md](./STORIES.md) — two stories
5. [x] [PLAN.md](./PLAN.md) — three tasks
6. [x] [BUILD-LOG.md](./BUILD-LOG.md) — three tasks, three commits

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
EOF
cat > docs/plans/tag-pinning/BRIEF.md <<'EOF'
# Tag pinning: brief

Editors want a few campaign tags at the front of the cloud, whatever their counts.
EOF
cat > docs/plans/tag-pinning/ARCHITECTURE.md <<'EOF'
# Tag pinning: architecture

- `PinnedTagStore` keeps each group's pinned tags in Umbraco's key-value store.
- `TagCloudService` puts pinned tags first, then the rest by count, and flags them.
- Two new routes on the existing `TagCloudController`: pin and unpin.
EOF
cat > docs/plans/tag-pinning/SPEC.md <<'EOF'
# Tag pinning: spec

- A pinned tag comes before every unpinned tag, in the order it was pinned.
- `TagCloudItem` says whether a tag is pinned.
- Pinning a tag that's already pinned does nothing.

## Management API surface
- `POST /umbraco/management/api/v1/tag-cloud/{group}/pins` — body `{ "tag": "..." }`
- `DELETE /umbraco/management/api/v1/tag-cloud/{group}/pins/{tag}`
Same access as the existing routes: anyone with access to the Content section.

## Frontend components
None in this PR.
EOF
cat > docs/plans/tag-pinning/STORIES.md <<'EOF'
# Tag pinning: stories

1. Pin a tag. 2. Unpin a tag.
EOF
cat > docs/plans/tag-pinning/PLAN.md <<'EOF'
# Tag pinning: plan

- [x] Add `PinnedTagStore` on the key-value store.
- [x] Put pinned tags first in `TagCloudService` and flag them on `TagCloudItem`.
- [x] Add pin and unpin routes to `TagCloudController`.
EOF
cat > docs/plans/tag-pinning/DECISION-LOG.md <<'EOF'
# Tag pinning: decision log

- 2026-10-12 (feature-design): Pins live in the key-value store, not a new table. The user
  chose this; a handful of strings per group doesn't need a migration.
EOF
cat > docs/plans/tag-pinning/BUILD-LOG.md <<'EOF'
# Tag pinning: build log

- Task 1 — `a1b2c3d` — PinnedTagStore; unit test.
- Task 2 — `d4e5f6a` — pinned tags first and flagged; unit tests.
- Task 3 — `b7c8d9e` — pin and unpin routes; integration test.
EOF
git add -A && git commit -qm "docs: add plan folder for tag-pinning"

# ---- the feature branch's changes ----
cat > $P/Models/TagCloudItem.cs <<'EOF'
namespace Umbraco.Community.TagCloud.Models;

public record TagCloudItem(string Text, int Weight, bool IsPinned);
EOF
cat > $P/Services/PinnedTagStore.cs <<'EOF'
using Umbraco.Cms.Core.Services;

namespace Umbraco.Community.TagCloud.Services;

public class PinnedTagStore(IKeyValueService keyValues)
{
    private static string Key(string group) => $"TagCloud.Pins.{group}";

    public IReadOnlyList<string> Get(string group) =>
        (keyValues.GetValue(Key(group)) ?? "").Split('\n', StringSplitOptions.RemoveEmptyEntries);

    public void Pin(string group, string tag)
    {
        var pins = Get(group).ToList();
        if (pins.Contains(tag)) return;
        pins.Add(tag);
        keyValues.SetValue(Key(group), string.Join('\n', pins));
    }

    public void Unpin(string group, string tag) =>
        keyValues.SetValue(Key(group), string.Join('\n', Get(group).Where(p => p != tag)));
}
EOF
cat > $P/Services/TagCloudService.cs <<'EOF'
using Umbraco.Cms.Core.Services;
using Umbraco.Community.TagCloud.Models;

namespace Umbraco.Community.TagCloud.Services;

public class TagCloudService(ITagService tagService, PinnedTagStore pins)
{
    public IReadOnlyList<TagCloudItem> GetCloud(string group)
    {
        var pinned = pins.Get(group);
        return tagService.GetAllContentTags(group)
            .OrderBy(t => pinned.Contains(t.Text) ? pinned.ToList().IndexOf(t.Text) : int.MaxValue)
            .ThenByDescending(t => t.NodeCount)
            .Select(t => new TagCloudItem(t.Text, t.NodeCount, pinned.Contains(t.Text)))
            .ToList();
    }
}
EOF
cat > $P/Controllers/TagCloudController.cs <<'EOF'
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Umbraco.Cms.Api.Management.Controllers;
using Umbraco.Cms.Api.Management.Routing;
using Umbraco.Cms.Web.Common.Authorization;
using Umbraco.Community.TagCloud.Services;

namespace Umbraco.Community.TagCloud.Controllers;

[ApiVersion("1.0")]
[VersionedApiBackOfficeRoute("tag-cloud")]
[ApiExplorerSettings(GroupName = "Tag Cloud")]
[Authorize(Policy = AuthorizationPolicies.SectionAccessContent)]
public class TagCloudController(TagCloudService cloud, PinnedTagStore pins) : ManagementApiControllerBase
{
    [HttpGet("{group}")]
    public IActionResult Get(string group) => Ok(cloud.GetCloud(group));

    [HttpGet("groups")]
    public IActionResult Groups([FromServices] ITagGroupLister lister) => Ok(lister.List());

    public record PinRequest(string Tag);

    [HttpPost("{group}/pins")]
    public IActionResult Pin(string group, PinRequest request)
    {
        pins.Pin(group, request.Tag);
        return NoContent();
    }

    [HttpDelete("{group}/pins/{tag}")]
    public IActionResult Unpin(string group, string tag)
    {
        pins.Unpin(group, tag);
        return NoContent();
    }
}
EOF
# git can't run inside the eval sandbox, so hand over the branch diff as a file.
git add -A && git diff --cached > CHANGE.diff && git reset -q --hard
cat > COMMITS.txt <<'EOF'
b7c8d9e feat(tag-pinning): add pin and unpin routes
d4e5f6a feat(tag-pinning): put pinned tags first and flag them
a1b2c3d feat(tag-pinning): store pinned tags per group
EOF
