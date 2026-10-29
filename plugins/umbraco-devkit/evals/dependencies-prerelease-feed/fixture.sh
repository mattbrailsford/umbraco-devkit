#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/Umbraco.Community.Insights
cat > CLAUDE.md <<'MD'
# Umbraco.Community.Insights

An Umbraco package with licensed features (Umbraco.Licenses). Branch per CMS major; this is
the new `v19/dev` line. The package version follows the CMS major.
MD
cat > NuGet.config <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
  </packageSources>
</configuration>
XML
cat > Directory.Build.props <<'XML'
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Version>18.1.0</Version>
  </PropertyGroup>
</Project>
XML
cat > Directory.Packages.props <<'XML'
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="Umbraco.Cms.Core" Version="[18.0.0, 18.999.999)" />
    <PackageVersion Include="Umbraco.Cms.Web.Common" Version="[18.0.0, 18.999.999)" />
    <PackageVersion Include="Umbraco.Licenses" Version="[18.0.0, 18.999.999)" />
  </ItemGroup>
</Project>
XML
cat > src/Umbraco.Community.Insights/Umbraco.Community.Insights.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Core" />
    <PackageReference Include="Umbraco.Cms.Web.Common" />
    <PackageReference Include="Umbraco.Licenses" />
  </ItemGroup>
</Project>
XML
cat > README.md <<'MD'
# Umbraco.Community.Insights

Editor insights for Umbraco.

## Installing

```bash
dotnet add package Umbraco.Community.Insights
```
MD
