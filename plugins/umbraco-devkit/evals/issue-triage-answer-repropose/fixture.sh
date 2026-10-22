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

Opened by @mira-k (not on the team)

Since I updated the package last week the tag cloud on our blog page shows nothing at all.
It worked fine before. Nothing else changed on our side. Can you help?

Labels: state/drafted

## Comments

### Comment 9001 by @jodean

<!-- issue-triage:proposal first=needs-investigation -->
<details><summary><b>Proposed: needs investigation</b> · automated first look, not decided</summary>

**Why:** the indexer only skips content when the `tags` property is missing, and the report
doesn't say which document types the blog page uses, or which versions.


**Notes for the next look**
- **Known so far:** cloud empty after an update; nothing else changed.
- **Checked:** TagIndexer.cs skips content with no `tags` property, and logs a warning.
- **Missing:** the versions, and the warning.
- **Likely area:** src/TagCloud/TagIndexer.cs

To answer: start a comment with 🤖.
</details>

### Comment 9002 by @mira-k

No warnings in the log at all. The tags are definitely saved on the posts.

### Comment 9003 by @jodean

🤖 look again, the reporter says nothing is logged, so it isn't the indexer. check the cache
EOF
cat > ACCESS.md <<'EOF'
Write access: @jodean
EOF
