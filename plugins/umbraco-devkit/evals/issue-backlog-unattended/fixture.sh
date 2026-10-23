#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.TagCloud

An Umbraco package (C# plus a Lit backoffice client).

## Version lines

| Line | Integration branch | Release branch | Phase |
|---|---|---|---|
| Umbraco 17 | `v17/dev` | `v17/main` | Active: features and fixes |
| Umbraco 13 | `v13/dev` | `v13/main` | Security fixes only, until 2026-12-14 |

## Issue tracker

- Type: GitHub Issues
- Location: this repo, `jodean/Umbraco.Community.TagCloud`
- Access: `gh`
- State labels: the defaults
EOF
mkdir -p src/TagCloud
cat > src/TagCloud/TagCloudOptions.cs <<'EOF2'
namespace TagCloud;

public sealed class TagCloudOptions
{
    public int MaxTags { get; set; } = 50;
}
EOF2
cat > src/TagCloud/TagCloudService.cs <<'EOF2'
namespace TagCloud;

internal sealed class TagCloudService
{
    private readonly ITagCache _cache;
    public TagCloudService(ITagCache cache) => _cache = cache;

    // Every tag, most used first.
    public IEnumerable<TagWeight> Build() =>
        _cache.All().GroupBy(t => t).Select(g => new TagWeight(g.Key, g.Count())).OrderByDescending(t => t.Count);
}
EOF2
cat > ISSUES.json <<'EOF'
[
  {"number": 101, "title": "Cloud ignores the MaxTags setting", "labels": [], "updatedAt": "2026-10-15", "author": "sam-o", "body": "I set TagCloud:MaxTags to 20 in appsettings.json but the cloud still shows every tag (about 300). Umbraco 17.1, package 4.2.0.", "comments": []},
  {"number": 102, "title": "Support tag groups in the Delivery API", "labels": [], "updatedAt": "2026-10-15", "author": "lin-p", "body": "We use the Delivery API for a headless site. Could the tag cloud endpoint take a tag group, so we can show one cloud per group?", "comments": []},
  {"number": 94, "title": "Show tag counts on hover", "labels": ["state/needs-decision"], "updatedAt": "2026-10-10"},
  {"number": 86, "title": "Crash on startup on Azure", "labels": ["state/needs-info"], "updatedAt": "2026-10-14", "note": "needs-info added 2026-10-14; no reply from the reporter since"},
  {"number": 80, "title": "Tags with spaces break the link", "labels": ["state/ready"], "updatedAt": "2026-10-08"},
  {"number": 82, "title": "Typo in the settings label", "labels": ["state/ready"], "updatedAt": "2026-10-08"},
  {"number": 79, "title": "Dark mode colours", "labels": ["state/in-progress"], "updatedAt": "2026-10-13"}
]
EOF
