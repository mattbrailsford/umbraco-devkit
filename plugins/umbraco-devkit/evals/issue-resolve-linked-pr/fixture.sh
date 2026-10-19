#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.VariantCache

An Umbraco package (C#).

## Version lines

| Line | Integration branch | Release branch | Phase |
|---|---|---|---|
| Umbraco 17 | `v17/dev` | `v17/main` | Active: features and fixes |

## Issue tracker

- Type: GitHub Issues
- Location: this repo, `jodean/Umbraco.Community.VariantCache`
- Access: `gh`
- State labels: the defaults
EOF
mkdir -p src/Umbraco.Community.VariantCache/Caching
cat > src/Umbraco.Community.VariantCache/Caching/VariantCacheRefresher.cs <<'EOF'
namespace Umbraco.Community.VariantCache.Caching;

public class VariantCacheRefresher : CacheRefresherBase<VariantCacheRefresherNotification>
{
    public override void Refresh(int id)
    {
        // builds the cache key from the default culture only
        var key = BuildKey(id);
        _cache.Remove(key);
        base.Refresh(id);
    }
}
EOF
cat > ISSUE-58.md <<'EOF'
# #58 CacheRefresherBase doesn't invalidate the per-site variant cache

Opened by: anna-contrib · Labels: state/ready

When a package overrides `CacheRefresherBase<T>` for a custom content variant, the in-memory
cache for non-default cultures never clears after a publish. Editors have to recycle the app
pool to see new content in secondary cultures.

**Linked pull request:** #61, opened by `anna-contrib` (not a core maintainer), still open.
Anna's PR description says it fixes this by including the culture in the cache key.

---

## Triage report (issue-triage, this morning)

- type: bug
- security: false
- state: state/ready
- likely area: `src/Umbraco.Community.VariantCache/Caching/VariantCacheRefresher.cs`
- linked PR: #61 (open, from anna-contrib, not a maintainer)

### Notes for the fix

- **Repro:** publish a document in a non-default culture, edit it again without an app pool
  recycle; the stale value is served.
- **Cause:** `VariantCacheRefresher.Refresh` builds the cache key from the default culture
  only.
- **Same cause elsewhere:** none found.
- **Suggested fix:** include the culture in the cache key. See PR #61, which already does
  this.
- **Size:** quick fix.
EOF
