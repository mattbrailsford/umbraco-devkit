#!/usr/bin/env bash
set -euo pipefail
git init -q -b v17/dev
git config user.email eval@example.com && git config user.name eval
git remote add origin https://github.com/example/My.Package.git
mkdir -p src/My.Package/Controllers src/My.Package/Services
cat > CLAUDE.md <<'MD'
# My Package

An Umbraco 17 package. One NuGet package, My.Package, versioned on its own.

## Feature workflow

Trunk branch: `v17/dev`. Release tags look like `My.Package@17.2.0`.

## Build & test

`dotnet build` and `dotnet test`. No demo site.

## Security process
- Report a vulnerability to: security@example.com
- Reports arrive as: a GitHub security advisory
- Read with: paste it
- Updates go to: the advisory's comments
- Security team needs: affected and fixed version ranges, release date
- Approves release: the maintainer
- Release timing: the security team agrees a severity. Critical or High: every supported line, patched at once. Moderate: every supported line, within a month. Low: decide whether to fix; if so, it ships in the next minor of the newest line, and supported older lines get a patch the same day.
- Private fork: GitHub advisory fork
- Advisory published by: the maintainer, once packages ship
MD
cat > src/My.Package/Services/DraftService.cs <<'CS'
namespace My.Package.Services;

public sealed class DraftService(IContentService contentService)
{
    public IEnumerable<IContent> GetDrafts(int skip, int take)
        => contentService.GetPagedOfType(0, skip, take, out _, null)
            .Where(c => !c.Published);
}
CS
cat > src/My.Package/Controllers/DraftsController.cs <<'CS'
namespace My.Package.Controllers;

[VersionedApiBackOfficeRoute("my-package/drafts")]
[ApiExplorerSettings(GroupName = "My Package")]
[Authorize(Policy = AuthorizationPolicies.SectionAccessContent)]
public sealed class DraftsController(DraftService drafts) : ManagementApiControllerBase
{
    [HttpGet]
    public IActionResult Get(int skip = 0, int take = 100)
        => Ok(drafts.GetDrafts(skip, take).Select(c => new { c.Key, c.Name }));
}
CS
git add -A && git commit -q -m "feat: list drafts" && git tag My.Package@17.0.0
echo "// paging" >> src/My.Package/Services/DraftService.cs
git commit -q -am "feat: page drafts" && git tag My.Package@17.1.0
git branch v16/dev My.Package@17.0.0
sed -i.bak '/SectionAccessContent/d' src/My.Package/Controllers/DraftsController.cs && rm src/My.Package/Controllers/DraftsController.cs.bak
git commit -q -am "refactor: tidy controller attributes"
echo "// sort" >> src/My.Package/Services/DraftService.cs
git commit -q -am "fix: sort drafts by date" && git tag My.Package@17.1.1
echo "// filter" >> src/My.Package/Services/DraftService.cs
git commit -q -am "feat: filter drafts by type" && git tag My.Package@17.2.0
git update-ref refs/remotes/origin/v17/dev v17/dev
git update-ref refs/remotes/origin/v16/dev v16/dev

mkdir -p "$(git rev-parse --git-common-dir)/umbraco-devkit/advisories"
cat > "$(git rev-parse --git-common-dir)/umbraco-devkit/advisories/GHSA-abcd-efgh-ijkl.md" <<'MD'
# GHSA-abcd-efgh-ijkl

PRIVATE. This file lives in the repo's `.git` folder and is never pushed.

- Report: the GitHub advisory
- Update channel: the advisory's comments
- Private fork: `example/My.Package-ghsa-abcd-efgh-ijkl`
- Embargoed branches: `v17/hotfix/draft-listing-access`

## Issues

### 1. Drafts endpoint readable without Content section access

- Status: confirmed
- Entry point: GET /umbraco/management/api/v1/my-package/drafts
- Cause: `DraftsController` has no `SectionAccessContent` policy
- From: the report

## Plan

Put the `SectionAccessContent` policy back on `DraftsController`, with a test that a user
without Content access gets 403. Approved by the maintainer. No release in progress. Only
the 17 line is supported.

Security team agreed severity: Low. We will fix it.

## Versions

[Not worked out yet.]

## Log

- Steps 1 to 4 done. Embargo recorded.
MD
git config --add devkit-embargo.GHSA-abcd-efgh-ijkl.branch v17/hotfix/draft-listing-access
