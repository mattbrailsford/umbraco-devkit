#!/usr/bin/env bash
set -euo pipefail

# A small stand-in for the CMS clone: the 19 beta the upgrade file targets, and rc1.
cms="$PWD/.cms"
mkdir -p "$cms/src/Umbraco.Core/Webhooks"
git -C "$cms" init -q
git -C "$cms" config user.email cms@example.com
git -C "$cms" config user.name CMS
git -C "$cms" remote add origin https://github.com/umbraco/Umbraco-CMS.git
cat > "$cms/Directory.Build.props" <<'XML'
<Project>
  <PropertyGroup>
    <TargetFramework>net11.0</TargetFramework>
  </PropertyGroup>
</Project>
XML
cat > "$cms/src/Umbraco.Core/Webhooks/WebhookFiringService.cs" <<'CS'
namespace Umbraco.Cms.Core.Webhooks;

public class WebhookFiringService
{
    public void Fire(string eventAlias) { }
}
CS
git -C "$cms" add -A
git -C "$cms" commit -qm "Release 19.0.0-beta1"
git -C "$cms" tag release-19.0.0-beta1
printf '\n// Log the event alias on failure\n' >> "$cms/src/Umbraco.Core/Webhooks/WebhookFiringService.cs"
git -C "$cms" commit -qam "Webhooks: log the event alias on failure (#99310)"
git -C "$cms" tag release-19.0.0-rc1

# GitHub can't be reached from the eval; a stand-in `gh` answers release queries only.
mkdir -p .tools
cat > .tools/gh <<'SH'
#!/usr/bin/env bash
case "$1 $2" in
  "release list")
    printf 'release-19.0.0-rc1\tPre-release\trelease-19.0.0-rc1\t2026-11-10T10:00:00Z\n'
    printf 'release-19.0.0-beta1\tPre-release\trelease-19.0.0-beta1\t2026-10-20T10:00:00Z\n'
    printf 'release-18.4.0\tLatest\trelease-18.4.0\t2026-10-14T10:00:00Z\n' ;;
  "release view")
    printf 'title:\trelease-19.0.0-rc1\n--\n## Bug fixes\n* Webhooks: log the event alias on failure by @cms-team in #99310\n' ;;
  "pr list") echo "[]" ;;
  *) echo "not available offline" >&2; exit 1 ;;
esac
SH
chmod +x .tools/gh

# The package repo: one branch per CMS major. v19/main was cut from v18/main at 18.3.0.
git init -q -b v18/main
git config user.email dev@example.com
git config user.name Dev
P=src/Umbraco.Community.StockLevels
mkdir -p $P/Services $P/Webhooks docs/upgrades
cat > .gitignore <<'TXT'
.cms/
.tools/
CLAUDE.local.md
TXT
cat > CLAUDE.md <<'MD'
# Umbraco.Community.StockLevels

Tracks stock per product. One branch per CMS major: `v18/main` (package 18.x, released) and
`v19/main` (package 19.x, in pre-release against the CMS 19 betas and RCs).
MD
cat > CLAUDE.local.md <<MD
- Umbraco CMS source: $cms
MD
cat > $P/Umbraco.Community.StockLevels.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Version>18.3.0</Version>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" Version="[18.0.0, 19.0.0)" />
  </ItemGroup>
</Project>
XML
cat > $P/Services/StockService.cs <<'CS'
namespace Umbraco.Community.StockLevels.Services;

internal sealed class StockService(IStockRepository repository) : IStockService
{
    public int GetLevel(Guid productKey, string? variant)
    {
        StockRow row = repository.Get(productKey);
        return row.Variants[variant!];
    }
}
CS
cat > $P/Webhooks/StockWebhookPayload.cs <<'CS'
namespace Umbraco.Community.StockLevels.Webhooks;

internal sealed class StockWebhookPayload
{
    public required Guid ProductKey { get; init; }
    public required int Level { get; init; }
    public DateTime Changed { get; init; } = DateTime.Now;
}
CS
git add -A
git commit -qm "feat: stock levels 18.3.0"
git tag v18.3.0

# The v19 line, cut here.
git checkout -q -b v19/main
sed -i.bak -e 's/net10.0/net11.0/' -e 's/18.3.0/19.0.0-beta1/' -e 's/\[18.0.0, 19.0.0)/[19.0.0-beta1, 20.0.0)/' $P/Umbraco.Community.StockLevels.csproj
rm $P/Umbraco.Community.StockLevels.csproj.bak
git commit -qam "chore: move to Umbraco 19.0.0-beta1 and .NET 11"
cat > docs/upgrades/v19.md <<'MD'
# Upgrade to Umbraco 19

From `18.0.0` to `19.0.0-beta1` (tag `release-19.0.0-beta1`).
Branch `v19/main`, cut from `v18/main` at `v18.3.0`.

**Targets CMS release:** `release-19.0.0-beta1`. The package ships `19.0.0-beta1`.

## Inventory

- **.NET 10 → .NET 11** (beta1)\
  Source: `release-19.0.0-beta1:Directory.Build.props`\
  Hits: every project

## Third-party dependencies

None offered.

## Stopgaps

None.

## Screen comparison

The package adds no screens.

## Docs

Docs: `README.md` in this repo. Nothing made wrong by this upgrade.

## Waiting on the CMS

None.

## Blockers

None.

## Tasks

- [x] Move to Umbraco 19.0.0-beta1, .NET 11, package 19.0.0-beta1

## Follow-ups

None.

## Backport candidates

None.

## Decisions

None.

## Log

- Move to Umbraco 19.0.0-beta1: chore commit on `v19/main`.
MD
git add -A
git commit -qm "docs: add upgrade plan for v19"

# Meanwhile on v18: two fixes released as patches.
git checkout -q v18/main
cat > $P/Services/StockService.cs <<'CS'
namespace Umbraco.Community.StockLevels.Services;

internal sealed class StockService(IStockRepository repository) : IStockService
{
    public int GetLevel(Guid productKey, string? variant)
    {
        StockRow row = repository.Get(productKey);
        if (variant is null)
        {
            return row.Total;
        }

        return row.Variants.TryGetValue(variant, out int level) ? level : 0;
    }
}
CS
git commit -qam "fix: stock level throws for products without variants (#212)"
sed -i.bak 's/18.3.0/18.3.1/' $P/Umbraco.Community.StockLevels.csproj && rm $P/Umbraco.Community.StockLevels.csproj.bak
git commit -qam "chore: release 18.3.1"
git tag v18.3.1
sed -i.bak 's/DateTime.Now;/DateTime.UtcNow;/' $P/Webhooks/StockWebhookPayload.cs && rm $P/Webhooks/StockWebhookPayload.cs.bak
git commit -qam "fix: webhook timestamps use the server's local time (#215)"
sed -i.bak 's/18.3.1/18.3.2/' $P/Umbraco.Community.StockLevels.csproj && rm $P/Umbraco.Community.StockLevels.csproj.bak
git commit -qam "chore: release 18.3.2"
git tag v18.3.2

# The #215 fix was carried to v19 by hand, under a different message.
git checkout -q v19/main
sed -i.bak 's/DateTime.Now;/DateTime.UtcNow;/' $P/Webhooks/StockWebhookPayload.cs && rm $P/Webhooks/StockWebhookPayload.cs.bak
git commit -qam "Use UTC in webhook payloads"
