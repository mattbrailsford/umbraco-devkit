#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'MD'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Open source; trunk branch: `main`.
MD
mkdir -p src/Umbraco.Community.TagCloud/Services src/Umbraco.Community.TagCloud/Models
cat > src/Umbraco.Community.TagCloud/Umbraco.Community.TagCloud.csproj <<'CS'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup><TargetFramework>net10.0</TargetFramework><Nullable>enable</Nullable></PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" Version="[17.0.0, 18.0.0)" />
  </ItemGroup>
</Project>
CS
cat > src/Umbraco.Community.TagCloud/Models/TagCloudSettings.cs <<'CS'
namespace Umbraco.Community.TagCloud.Models;

/// <summary>The Tag Cloud data type's settings.</summary>
public class TagCloudSettings
{
    public string Group { get; set; } = "default";

    /// <summary>The most tags the cloud shows. Empty (null) shows every tag.</summary>
    public int? MaxTags { get; set; }
}
CS
cat > src/Umbraco.Community.TagCloud/Services/TagCloudService.cs <<'CS'
using Umbraco.Cms.Core.Models;
using Umbraco.Cms.Core.Services;
using Umbraco.Community.TagCloud.Models;

namespace Umbraco.Community.TagCloud.Services;

public class TagCloudService(ITagService tagService)
{
    public IEnumerable<ITag> GetTags(TagCloudSettings settings) =>
        tagService.GetAllContentTags(settings.Group)
            .OrderByDescending(tag => tag.NodeCount);
}
CS
git add -A && git commit -q -m "feat: tag cloud service"
git checkout -q -b respect-max-tags
cat > src/Umbraco.Community.TagCloud/Services/TagCloudService.cs <<'CS'
using Umbraco.Cms.Core.Models;
using Umbraco.Cms.Core.Services;
using Umbraco.Community.TagCloud.Models;

namespace Umbraco.Community.TagCloud.Services;

public class TagCloudService(ITagService tagService)
{
    public IEnumerable<ITag> GetTags(TagCloudSettings settings) =>
        tagService.GetAllContentTags(settings.Group)
            .OrderByDescending(tag => tag.NodeCount)
            .Take(settings.MaxTags ?? 0);
}
CS
git add -A && git diff --cached HEAD > PR.diff
git commit -q -m "fix: respect the MaxTags setting"
SHA=$(git rev-parse HEAD)
cat > PR.json <<JSON
{
  "number": 158,
  "title": "Respect the MaxTags setting",
  "body": "Fixes #101. The cloud ignored MaxTags and showed every tag. It now takes at most MaxTags.",
  "author": {"login": "sofie-h"},
  "authorAssociation": "CONTRIBUTOR",
  "baseRefName": "main",
  "headRefName": "respect-max-tags",
  "headRefOid": "$SHA",
  "maintainerCanModify": true,
  "files": [{"path": "src/Umbraco.Community.TagCloud/Services/TagCloudService.cs", "additions": 1, "deletions": 0}],
  "closingIssuesReferences": [{"number": 101}],
  "reviews": [],
  "mergeable": "MERGEABLE",
  "checks": [{"name": "build", "state": "SUCCESS"}, {"name": "test", "state": "SUCCESS"}]
}
JSON
cat > REPO.json <<'JSON'
{
  "defaultBranch": "main",
  "mergeCommitAllowed": true,
  "squashMergeAllowed": true,
  "rebaseMergeAllowed": false,
  "recentMerges": [{"number": 150, "method": "squash"}, {"number": 147, "method": "squash"}]
}
JSON
