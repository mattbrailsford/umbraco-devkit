#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/OrderExports.Core/Exports src/OrderExports.Deploy src/OrderExports.Automate .github/workflows
cat > CLAUDE.md <<'MD'
# Order Exports

An Umbraco 18 package that exports orders to CSV. Three NuGet packages, one version line
(`main`). The package version follows the CMS major (18.x for Umbraco 18).

- `OrderExports.Core`: the exporter and its backoffice dashboard. Needs only the CMS.
- `OrderExports.Deploy`: a Deploy connector so export profiles move between environments.
- `OrderExports.Automate`: an Automate action that runs an export.

Releases, including pre-releases, publish all three packages to NuGet.org from
`.github/workflows/release.yml`.
MD
cat > Directory.Packages.props <<'XML'
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <PackageVersion Include="Umbraco.Cms.Web.Common" Version="[18.2.0, 19.0.0)" />
    <PackageVersion Include="Umbraco.Cms.Api.Management" Version="[18.2.0, 19.0.0)" />
    <PackageVersion Include="Umbraco.Deploy.Infrastructure" Version="[18.1.0, 19.0.0)" />
    <PackageVersion Include="Umbraco.Automate.Core" Version="[18.0.3, 19.0.0)" />
  </ItemGroup>
</Project>
XML
cat > Directory.Build.props <<'XML'
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Version>18.4.0</Version>
  </PropertyGroup>
</Project>
XML
cat > NuGet.config <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
  </packageSources>
</configuration>
XML
cat > src/OrderExports.Core/OrderExports.Core.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" />
    <PackageReference Include="Umbraco.Cms.Api.Management" />
  </ItemGroup>
</Project>
XML
cat > src/OrderExports.Core/Exports/ExportProfile.cs <<'CS'
namespace OrderExports.Core.Exports;

public sealed class ExportProfile
{
    public Guid Key { get; set; }
    public string Name { get; set; } = string.Empty;
    public string[] Columns { get; set; } = [];
}
CS
cat > src/OrderExports.Core/Exports/IExportProfileService.cs <<'CS'
namespace OrderExports.Core.Exports;

public interface IExportProfileService
{
    Task<ExportProfile?> GetAsync(Guid key);
    Task<IEnumerable<ExportProfile>> GetAllAsync();
    Task SaveAsync(ExportProfile profile);
}
CS
cat > src/OrderExports.Deploy/OrderExports.Deploy.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk">
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
        return profile is null ? null : new ExportProfileArtifact(udi, profile.Name, profile.Columns);
    }
}
CS
cat > src/OrderExports.Automate/OrderExports.Automate.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk">
  <ItemGroup>
    <PackageReference Include="Umbraco.Automate.Core" />
    <ProjectReference Include="../OrderExports.Core/OrderExports.Core.csproj" />
  </ItemGroup>
</Project>
XML
cat > src/OrderExports.Automate/RunExportAction.cs <<'CS'
using OrderExports.Core.Exports;
using Umbraco.Automate.Core.Actions;

namespace OrderExports.Automate;

[AutomateAction("orderExports.runExport", "Run order export")]
public sealed class RunExportAction : AutomateActionBase<RunExportSettings>
{
    private readonly IExportProfileService _profiles;

    public RunExportAction(IExportProfileService profiles) => _profiles = profiles;

    public override async Task<ActionResult> ExecuteAsync(ActionContext<RunExportSettings> context)
    {
        var profile = await _profiles.GetAsync(context.Settings.ProfileKey);
        return profile is null ? ActionResult.Failed("Profile not found") : ActionResult.Success();
    }
}

public sealed class RunExportSettings
{
    public Guid ProfileKey { get; set; }
}
CS
cat > .github/workflows/release.yml <<'YML'
name: release
on:
  push:
    tags: ['v*']
jobs:
  pack:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with: { dotnet-version: '10.0.x' }
      - run: dotnet pack -c Release -o out
      - run: dotnet nuget push "out/*.nupkg" -k ${{ secrets.NUGET_API_KEY }} -s https://api.nuget.org/v3/index.json
YML
