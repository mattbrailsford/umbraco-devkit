#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.TagCloud

An Umbraco package (C# plus a Lit backoffice client).

## Issue tracker

- Type: GitHub Issues
- Location: this repo, `jodean/Umbraco.Community.TagCloud`
- Access: `gh`
- State labels: the defaults
- Proposal answers: start a comment with 🤖
EOF
mkdir -p src/TagCloud
cat > src/TagCloud/TagIndexer.cs <<'EOF'
namespace TagCloud;

internal sealed class TagIndexer : INotificationHandler<ContentPublishedNotification>
{
    private readonly ILogger<TagIndexer> _logger;
    private readonly ITagCache _cache;
    public TagIndexer(ILogger<TagIndexer> logger, ITagCache cache) { _logger = logger; _cache = cache; }

    public void Handle(ContentPublishedNotification notification)
    {
        foreach (var content in notification.PublishedEntities)
        {
            var tags = content.GetValue<string>("tags");
            if (tags is null)
            {
                _logger.LogWarning("TagCloud: no tags property on {ContentType}", content.ContentType.Alias);
                continue;
            }
            _cache.Add(content.Id, tags.Split(','));
        }
    }
}
EOF
cat > src/TagCloud/TagCache.cs <<'EOF'
namespace TagCloud;

internal sealed class TagCache : ITagCache
{
    private readonly IAppPolicyCache _runtimeCache;
    public TagCache(AppCaches caches) => _runtimeCache = caches.RuntimeCache;

    // Keyed per content item; the cloud reads every key with the prefix.
    public void Add(int contentId, string[] tags) =>
        _runtimeCache.Insert($"tagcloud-{contentId}", () => tags, TimeSpan.FromHours(1));

    public IEnumerable<string> All() =>
        _runtimeCache.SearchByKey("tagcloud_").OfType<string[]>().SelectMany(t => t);
}
EOF
cat > ISSUE-140.md <<'EOF'
# #140: Tag cloud is empty since updating

Opened by @jodean

Since updating the package, the tag cloud on the demo blog shows nothing at all. The posts
still have tags.

Labels: state/drafted

## Comments

### Comment 9001 by @jodean

<!-- issue-triage:proposal first=ready -->
<details><summary><b>Proposed: ready</b> · automated first look, not decided</summary>

**Why:** the cache writes keys starting `tagcloud-` but reads keys starting `tagcloud_`, so
the cloud never finds anything.

**Notes for the fix**
- **Repro:** not run; read from the code.
- **Cause:** `src/TagCloud/TagCache.cs:10` inserts `tagcloud-{contentId}`; line 13 searches `tagcloud_`.
- **Same cause elsewhere:** none found.
- **Suggested fix:** one shared prefix constant, and a test that adds tags and reads them back.
- **Size:** quick fix.

To answer: start a comment with 🤖.
</details>

### Comment 9002 by @jodean

🤖 approve
EOF
cat > ACCESS.md <<'EOF'
Write access: @jodean
EOF
