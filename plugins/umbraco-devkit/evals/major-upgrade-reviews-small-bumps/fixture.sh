#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/upgrades src/OrderExports.Core
cat > CLAUDE.md <<'MD'
# Order Exports

An Umbraco package that exports orders to CSV. Branch-per-major: `v18/dev`, `v19/dev`.
The package version follows the CMS major.
MD
cat > Directory.Packages.props <<'XML'
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="Umbraco.Cms.Web.Common" Version="[19.0.0-rc2, 20.0.0)" />
    <PackageVersion Include="Umbraco.Cms.Api.Management" Version="[19.0.0-rc2, 20.0.0)" />
    <PackageVersion Include="CsvHelper" Version="33.0.1" />
  </ItemGroup>
</Project>
XML
cat > builder-task9.diff <<'DIFF'
--- a/Directory.Packages.props
+++ b/Directory.Packages.props
@@ -4,8 +4,8 @@
   </PropertyGroup>
   <ItemGroup>
-    <PackageVersion Include="Umbraco.Cms.Web.Common" Version="[19.0.0-rc1, 20.0.0)" />
-    <PackageVersion Include="Umbraco.Cms.Api.Management" Version="[19.0.0-rc1, 20.0.0)" />
-    <PackageVersion Include="CsvHelper" Version="33.1.0" />
+    <PackageVersion Include="Umbraco.Cms.Web.Common" Version="[19.0.0-rc2, 20.0.0)" />
+    <PackageVersion Include="Umbraco.Cms.Api.Management" Version="[19.0.0-rc2, 20.0.0)" />
+    <PackageVersion Include="CsvHelper" Version="33.0.1" />
   </ItemGroup>
 </Project>
DIFF
cat > docs/upgrades/v19.md <<'MD'
# Upgrade to Umbraco 19

From 18.4.0 to 19.0.0-rc2 (tag `release-19.0.0-rc2`). Branch `v19/dev`, cut from `v18/dev`.

**Targets CMS release:** `release-19.0.0-rc2`. The package's own version is `19.0.0-rc2`.

## Inventory

- Target framework stays `net10.0`. No shared dependency moves between rc1 and rc2.
- rc1 to rc2: no breaking change hits the package (CMS diff and release notes read 14-11-2026).

## Blockers

None.

## Tasks

Each task ends in a green build.

- [x] 1. Fix obsolete usages on 18.x
- [x] 2. Bump to `release-19.0.0-beta1` and fix compile errors
- [x] 3. Move off APIs beta1 made obsolete
- [x] 4. Frontend bump to `@umbraco-cms/backoffice` 19.0.0-beta1
- [x] 5. Compatibility markers
- [x] 6. Refresh: move to `release-19.0.0-rc1`
- [x] 7. Forward-port v18 fix #231 (CsvHelper 33.1.0, quoted newlines in order notes)
- [x] 8. Fixes from older lines: none missing as of rc1
- [ ] 9. Refresh: move the CMS packages, `@umbraco-cms/backoffice` and the package version to `release-19.0.0-rc2`

## Decisions

None.

## Follow-ups

None.

## Log

- Task 1: `a1c3e02`
- Task 2: `4be91d7`
- Task 3: `77f0a1c`
- Task 4: `c08d2e5`
- Task 5: `19ad4f0`
- Task 6: `5e2b9a3`
- Task 7: `d41e8c6` (CsvHelper 33.0.1 to 33.1.0, fixes #231)
- Task 8: no change
MD
cat > src/OrderExports.Core/OrderExports.Core.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Version>19.0.0-rc2</Version>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" />
    <PackageReference Include="Umbraco.Cms.Api.Management" />
    <PackageReference Include="CsvHelper" />
  </ItemGroup>
</Project>
XML
