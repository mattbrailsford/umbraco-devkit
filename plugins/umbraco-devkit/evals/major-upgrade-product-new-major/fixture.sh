#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/OrderExports.Core src/OrderExports.Deploy
cat > CLAUDE.md <<'MD'
# Order Exports

An Umbraco package that exports orders to CSV. Branch-per-major: `v18/dev`, `v19/dev`
(this checkout, on the CMS 19 pre-releases). The package version follows the CMS major.

- `OrderExports.Core`: the exporter. Needs only the CMS.
- `OrderExports.Deploy`: a Deploy connector so export profiles move between environments.
MD
cat > Directory.Packages.props <<'XML'
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="Umbraco.Cms.Web.Common" Version="[19.0.0-rc1, 20.0.0)" />
    <PackageVersion Include="Umbraco.Deploy.Infrastructure" Version="[18.1.0, 19.0.0)" />
  </ItemGroup>
</Project>
XML
cat > Directory.Build.props <<'XML'
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Version>19.0.0-rc1</Version>
  </PropertyGroup>
</Project>
XML
cat > src/OrderExports.Core/OrderExports.Core.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" />
  </ItemGroup>
</Project>
XML
cat > src/OrderExports.Deploy/OrderExports.Deploy.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk">
  <!-- Left out of the v19 build and pack until there is a Deploy 19. -->
  <PropertyGroup>
    <IsPackable>false</IsPackable>
    <ExcludeFromBuild>true</ExcludeFromBuild>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Deploy.Infrastructure" />
    <ProjectReference Include="../OrderExports.Core/OrderExports.Core.csproj" />
  </ItemGroup>
</Project>
XML
cat > src/OrderExports.Deploy/ExportProfileServiceConnector.cs <<'CS'
using OrderExports.Core.Exports;
using Umbraco.Cms.Core.Deploy;
using Umbraco.Deploy.Infrastructure.Connectors.ServiceConnectors;

namespace OrderExports.Deploy;

[UdiDefinition("order-export-profile", UdiType.GuidUdi)]
public sealed class ExportProfileServiceConnector : ServiceConnectorBase<ExportProfileArtifact, GuidUdi, ExportProfile>
{
    private readonly IExportProfileService _profiles;

    public ExportProfileServiceConnector(IExportProfileService profiles) => _profiles = profiles;

    public override async Task<ExportProfileArtifact?> GetArtifactAsync(GuidUdi udi, IContextCache contextCache, CancellationToken cancellationToken = default)
    {
        var profile = await _profiles.GetAsync(udi.Guid);
        return profile is null ? null : new ExportProfileArtifact(udi, profile.Name);
    }
}
CS
