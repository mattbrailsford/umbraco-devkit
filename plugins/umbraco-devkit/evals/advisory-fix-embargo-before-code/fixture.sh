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
