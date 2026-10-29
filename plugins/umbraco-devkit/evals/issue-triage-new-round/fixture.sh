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

Opened by @mira-k

Since I updated the package last week the tag cloud on our blog page shows nothing at all.
It worked fine before. Nothing else changed on our side. Can you help?

Labels: state/needs-info

## Comments

### Comment 9001 by @jodean

<!-- issue-triage:proposal first=needs-info -->
<details><summary><b>Approved: needs info</b> · by @jodean</summary>

**Why:** the indexer only skips content when the `tags` property is missing, and the report
doesn't say which versions it moved between.

**Info needed:**
- Which package version they updated from and to: the property lookup changed in 3.0.

**Notes for the next look**
- **Known so far:** cloud empty after an update; nothing else changed.
- **Checked:** TagIndexer.cs skips content with no `tags` property, and logs a warning.
- **Likely area:** src/TagCloud/TagIndexer.cs

To answer: start a comment with 🤖.
</details>

### Comment 9002 by @jodean

<!-- issue-triage:reply -->
Thanks for the report! Could you tell us which version of the package you updated from, and
which you're on now? That tells us whether a change in 3.0 is behind this.

### Comment 9003 by @mira-k

From 2.4.1 to 3.1.0.
EOF
cat > ACCESS.md <<'EOF'
Write access: @jodean
EOF
