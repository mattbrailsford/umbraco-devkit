#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/upgrades src/OrderExports.Core demo/OrderExports.Demo .github/workflows
cat > CLAUDE.md <<'MD'
# Order Exports

An Umbraco package that exports orders to CSV. Branch-per-major: `v18/dev`, `v19/dev`.
The package version follows the CMS major. Demo site: `demo/OrderExports.Demo`.

- Build: `dotnet build OrderExports.slnx`
- Test: `dotnet test OrderExports.slnx` (SQLite and SQL Server)
- Releases: tag `v*` on a release branch; `.github/workflows/release.yml` packs and pushes.
MD
cat > global.json <<'J'
{ "sdk": { "version": "10.0.100-rc.2.25502.107", "allowPrerelease": true } }
J
cat > NuGet.config <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
    <add key="umbracoprereleases" value="https://www.myget.org/F/umbracoprereleases/api/v3/index.json" />
  </packageSources>
</configuration>
XML
cat > .github/workflows/ci.yml <<'YML'
name: ci
on:
  pull_request:
    branches: ['v*/dev']
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with: { dotnet-version: '10.0.x' }
      - run: dotnet restore --locked-mode
      - run: dotnet build -c Release --no-restore
      - run: dotnet test -c Release --no-build
YML
cat > docs/upgrades/v19.md <<'MD'
# Upgrade to Umbraco 19

From 18.4.0 to 19.0.0-rc1 (tag `release-19.0.0-rc1`). Branch `v19/dev`, cut from `v18/dev`.

**Targets CMS release:** `release-19.0.0-rc1`. The package's own version is `19.0.0-rc1`.

## Inventory

- Target framework stays `net10.0`; the CMS rc1 builds on the .NET 10 preview SDK in
  `global.json`.
- Umbraco pre-release feed added to `NuGet.config` for the CMS rc1; lock files regenerated.
- `IOrderNotesConverter` moved namespace (CMS PR #20811).
- The export dashboard's `umb-table` columns API changed (CMS PR #20777).

## Screen comparison

| Screen | Click path | Result |
|---|---|---|
| Export dashboard | Settings > Order Exports | not run |
| Export profile editor | Settings > Order Exports > a profile | not run |

## Blockers

None.

## Tasks

- [x] 1. Fix obsolete usages on 18.x
- [x] 2. Bump to `release-19.0.0-rc1`, pre-release feed, preview SDK; fix compile errors
- [x] 3. Move `IOrderNotesConverter` to its new namespace
- [x] 4. Frontend bump to `@umbraco-cms/backoffice` 19.0.0-rc1; table columns API
- [x] 5. Compatibility markers: `19.0.0-rc1`, README table

## Backport candidates

None.

## Follow-ups

None.

## Log

- Task 1: `a1c3e02`
- Task 2: `4be91d7`
- Task 3: `77f0a1c`
- Task 4: `c08d2e5`
- Task 5: `19ad4f0`
MD
