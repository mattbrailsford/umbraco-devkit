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
cat > src/OrderExports.Deploy/OrderExportsDeployComposer.cs <<'CS'
using Umbraco.Cms.Core.Composing;
using Umbraco.Cms.Core.DependencyInjection;

namespace OrderExports.Deploy;

public sealed class OrderExportsDeployComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder)
        => UdiParser.RegisterUdiType("order-export-profile", UdiType.GuidUdi);
}
CS
cat > src/OrderExports.Deploy/client-entity-actions.ts <<'TS'
// Registers the "Transfer" action for export profiles in the backoffice tree.
export const manifests = [
  {
    type: 'entityAction',
    alias: 'OrderExports.Deploy.Transfer',
    name: 'Transfer export profile',
    forEntityTypes: ['order-export-profile'],
  },
];
TS

# GitHub as a package developer outside Umbraco HQ sees it: Deploy's source repo is private
# (404), there are no releases, and the public issue tracker has an issue that names this
# package and lists the two changes it needs.
mkdir -p .tools
cat > .tools/gh <<'SH'
#!/usr/bin/env bash
args="$*"
issue_body='Deploy 19 registers UDI types automatically from [UdiDefinition], so a package calling UdiParser.RegisterUdiType itself now does nothing and the call can go. In the BackOfficeOnly edition, every disk entity type is now also a transfer entity type, so a package with its own disk entity type must register a transfer entity action for it, or the type has no Transfer action. Packages known to be affected: Umbraco.Commerce.Deploy, OrderExports.Deploy.'
notfound() { echo 'GraphQL: Could not resolve to a Repository with the name '"'"'umbraco/Umbraco.Deploy'"'"'. (repository)' >&2; exit 1; }
if [[ "$args" == *"Umbraco.Deploy.Issues"* ]]; then
  case "$1 $2" in
    "search issues")
      if [[ "$args" == *OrderExports* || "$args" == *19* || "$args" == *UdiDefinition* || "$args" == *[Bb]reaking* ]]; then
        printf 'umbraco/Umbraco.Deploy.Issues\t412\tOPEN\tDeploy 19: entity type registration changes for package authors\n'
      fi ;;
    "issue view")
      if [[ "$3" == 412 || "$args" == *"/412"* ]]; then
        printf 'title:\tDeploy 19: entity type registration changes for package authors\nstate:\tOPEN\n--\n%s\n' "$issue_body"
      else echo "issue not found" >&2; exit 1; fi ;;
    "issue list")
      printf '412\tOPEN\tDeploy 19: entity type registration changes for package authors\n'
      printf '409\tOPEN\tTransfer dialog cut off on small screens\n'
      printf '405\tCLOSED\tSchema comparison slow on large sites\n' ;;
    *) echo "not available offline" >&2; exit 1 ;;
  esac
  exit 0
fi
if [[ "$args" == *"Umbraco.Deploy"* ]]; then notfound; fi
case "$1 $2" in
  "release list"|"release view") echo "no releases found" >&2; exit 1 ;;
  "search prs"|"search issues"|"search code") ;;
  *) echo "not available offline" >&2; exit 1 ;;
esac
SH
chmod +x .tools/gh
