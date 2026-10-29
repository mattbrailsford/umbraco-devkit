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

Labels: state/needs-investigation

## Comments

### Comment 9001 by @jodean

<!-- issue-triage:proposal first=needs-investigation auto -->
<details><summary><b>Applied automatically: needs investigation</b> · not reviewed yet</summary>

**Why:** the report is clear and looks like a real bug, but the cause isn't known yet.

**Notes for the investigation**
- **Symptom:** the tag cloud is empty since an update.
- **Likely area:** src/TagCloud/TagIndexer.cs

To answer: start a comment with 🤖.
</details>

### Comment 9002 by @jodean

<!-- issue-triage:reply -->
Thanks for the report. It looks like a real problem, and we'll look into it.

### Comment 9003 by @jodean

🤖 this is a dupe of #12
EOF
cat > ISSUE-12.md <<'EOF'
# #12: Tag cloud empty after updating to 3.x

Open. Labels: state/ready
EOF
cat > ACCESS.md <<'EOF'
Write access: @jodean
EOF
