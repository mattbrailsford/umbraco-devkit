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
- Auto-apply: needs-investigation, needs-decision
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
cat > ISSUE-102.md <<'EOF'
# #102: Support tag groups in the Delivery API

Opened by @lin-p

We use the Delivery API for a headless site. Could the tag cloud endpoint take a tag group, so
we can show one cloud per group?
EOF
cat > ACCESS.md <<'EOF'
Write access: @jodean
EOF
