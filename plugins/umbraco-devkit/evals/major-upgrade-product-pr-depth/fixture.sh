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

# Umbraco Deploy's repo, as the real `gh` would show it: 80 merged PRs on v19/dev, newest
# first, 30 per page unless --limit says otherwise. No `category/breaking` labels and no
# GitHub release for the beta. The PR that breaks this package is old enough to sit past the
# first page, has a vague title, and only its description (or a search for the package's
# name) shows it.
mkdir -p .tools
cat > .tools/gh <<'SH'
#!/usr/bin/env bash
args="$*"
body_for() {
  case "$1" in
    2104) echo 'Entity types now register their UDI type automatically from [UdiDefinition], so packages no longer call UdiParser.RegisterUdiType themselves; a manual call is now a no-op. In the BackOfficeOnly edition, every disk entity type is now also a transfer entity type, so a package with its own disk entity type must register a transfer entity action for it, or the type has no Transfer action. Downstream packages to update: Umbraco.Commerce.Deploy, OrderExports.Deploy.' ;;
    2101) echo 'Targets Umbraco.Cms 19.0.0-beta1. ServiceConnectorBase.GetArtifactAsync now takes a CancellationToken.' ;;
    *) echo 'Internal change. No public API affected.' ;;
  esac
}
title_for() {
  case "$1" in
    2104) echo 'Entity type registration tidy-up for v19' ;;
    2101) echo 'Move to CMS 19 beta' ;;
    *) titles=('Fix typo in transfer dialog' 'Bump dependencies' 'Improve logging in schema comparison' 'Update localization keys' 'Refactor artifact signature cache' 'Tidy up test fixtures' 'Speed up disk read of large schema folders' 'Clarify restore progress messages' 'Update CI pipeline' 'Remove unused helper')
       echo "${titles[$(( $1 % ${#titles[@]} ))]} (#$1)" | sed 's/ (#[0-9]*)$//' ;;
  esac
}
case "$1 $2" in
  "release list"|"release view") echo "no releases found" >&2; exit 1 ;;
  "pr list")
    if [[ "$args" == *"--label"* ]]; then echo "[]"; exit 0; fi
    limit=30
    [[ "$args" =~ (-L|--limit)[\ =]([0-9]+) ]] && limit=${BASH_REMATCH[2]}
    want_body=0; [[ "$args" == *"--json"* && "$args" == *body* ]] && want_body=1
    n=0; first=1
    [[ "$args" == *"--json"* ]] && echo "["
    for ((pr=2180; pr>=2101; pr--)); do
      (( n >= limit )) && break; n=$((n+1))
      t=$(title_for $pr); day=$(( 1 + (pr - 2101) * 9 / 80 ))
      if [[ "$args" == *"--json"* ]]; then
        (( first )) || echo ","; first=0
        printf '{"number":%d,"title":"%s","mergedAt":"2026-11-%02dT09:00:00Z","baseRefName":"v19/dev","state":"MERGED"' $pr "$t" $day
        (( want_body )) && printf ',"body":"%s"' "$(body_for $pr)"
        printf '}'
      else
        printf '%d\t%s\tv19/dev\tMERGED\n' $pr "$t"
      fi
    done
    [[ "$args" == *"--json"* ]] && echo "]" ;;
  "pr view")
    if [[ "$3" =~ ^[0-9]+$ ]] && (( $3 >= 2101 && $3 <= 2180 )); then
      printf 'title:\t%s\nstate:\tMERGED\n--\n%s\n' "$(title_for $3)" "$(body_for $3)"
    else echo "no pull request found" >&2; exit 1; fi ;;
  "search prs")
    if [[ "$args" == *OrderExports* ]]; then
      printf 'umbraco/Umbraco.Deploy\t2104\tMERGED\tEntity type registration tidy-up for v19\n'
    fi ;;
  "search issues") ;;
  *) echo "not available offline" >&2; exit 1 ;;
esac
SH
chmod +x .tools/gh
