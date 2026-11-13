#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/Umbraco.Community.Insights/Client
cat > CLAUDE.md <<'MD'
# Umbraco.Community.Insights

An Umbraco package with licensed features (Umbraco.Licenses). Branch per CMS major; this is
the `v19/dev` line, currently on Umbraco 19.0.0-beta1. Restores use lock files.
MD
nuget_config() {
cat <<XML
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
$1    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
  </packageSources>
  <packageSourceMapping>
$2    <packageSource key="nuget.org">
      <package pattern="*" />
    </packageSource>
  </packageSourceMapping>
</configuration>
XML
}
nuget_config "" "" > NuGet.config
nuget_config '    <add key="LocalCI" value="./artifacts/nupkg" />
' '    <packageSource key="LocalCI">
      <package pattern="Umbraco.Community.Insights*" />
    </packageSource>
' > NuGet.CI.config
cat > azure-pipelines.yml <<'YML'
trigger: [v19/dev]
pool: { vmImage: ubuntu-latest }
steps:
  - script: dotnet restore --locked-mode
  - script: dotnet build -c Release --no-restore
  - script: dotnet pack -c Release -o artifacts/nupkg --no-build
  - script: dotnet restore tests/Umbraco.Community.Insights.PackTests --configfile NuGet.CI.config --locked-mode
    displayName: Restore pack tests against the packed package
  - script: cd src/Umbraco.Community.Insights/Client && npm ci && npm run build
YML
cat > Directory.Build.props <<'XML'
<Project>
  <PropertyGroup>
    <TargetFramework>net11.0</TargetFramework>
    <Version>19.0.0-beta1</Version>
    <RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
  </PropertyGroup>
</Project>
XML
cat > Directory.Packages.props <<'XML'
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="Umbraco.Cms.Core" Version="[19.0.0-beta1, 19.999.999)" />
    <PackageVersion Include="Umbraco.Cms.Web.Common" Version="[19.0.0-beta1, 19.999.999)" />
    <PackageVersion Include="Umbraco.Licenses" Version="[19.0.0-beta1, 19.999.999)" />
    <PackageVersion Include="Umbraco.Code" Version="3.0.0-beta" />
  </ItemGroup>
</Project>
XML
cat > src/Umbraco.Community.Insights/Umbraco.Community.Insights.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Core" />
    <PackageReference Include="Umbraco.Cms.Web.Common" />
    <PackageReference Include="Umbraco.Licenses" />
    <PackageReference Include="Umbraco.Code" PrivateAssets="all" />
  </ItemGroup>
</Project>
XML
cat > src/Umbraco.Community.Insights/packages.lock.json <<'JSON'
{
  "version": 2,
  "dependencies": {
    "net11.0": {
      "Umbraco.Cms.Core": { "type": "Direct", "requested": "[19.0.0-beta1, 19.999.999)", "resolved": "19.0.0-beta1", "contentHash": "q1Xh0beta1CoreHash==" },
      "Umbraco.Code": { "type": "Direct", "requested": "[3.0.0-beta, )", "resolved": "3.0.0-beta", "contentHash": "Zc0deNugetOrgHash==" }
    }
  }
}
JSON
cat > src/Umbraco.Community.Insights/Client/package.json <<'JSON'
{
  "name": "umbraco-community-insights-client",
  "private": true,
  "type": "module",
  "scripts": { "build": "vite build" },
  "peerDependencies": { "@umbraco-cms/backoffice": "^19.0.0-beta1" },
  "devDependencies": {
    "@umbraco-cms/backoffice": "19.0.0-beta1",
    "typescript": "^5.9.0",
    "vite": "^7.1.0"
  }
}
JSON
cat > src/Umbraco.Community.Insights/Client/package-lock.json <<'JSON'
{
  "name": "umbraco-community-insights-client",
  "lockfileVersion": 3,
  "packages": {
    "node_modules/@umbraco-cms/backoffice": {
      "version": "19.0.0-beta1",
      "resolved": "https://registry.npmjs.org/@umbraco-cms/backoffice/-/backoffice-19.0.0-beta1.tgz"
    }
  }
}
JSON
