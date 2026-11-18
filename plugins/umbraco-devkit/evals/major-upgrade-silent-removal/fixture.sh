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

    // Export profiles are flat: there is nothing below a profile, so only "this" makes sense.
    public override Task<NamedUdiRange> GetRangeAsync(string entityType, string sid, string selector, IContextCache contextCache)
    {
        if (selector != "this")
        {
            throw new NotSupportedException($"Selector '{selector}' is not supported for export profiles.");
        }

        var udi = new GuidUdi(entityType, Guid.Parse(sid));
        return Task.FromResult(new NamedUdiRange(udi, "this"));
    }
}
CS

# A local clone of Umbraco Deploy with the two release tags.
D=.deploy
mkdir -p $D
(
  cd $D
  git init -q -b main
  git config user.email deploy@example.com
  git config user.name "Deploy team"
  I=src/Umbraco.Deploy.Infrastructure
  mkdir -p $I/Connectors/ServiceConnectors $I/Trees $I/Restore $I/Disk
  cat > $I/Connectors/ServiceConnectors/ServiceConnectorBase.cs <<'CS'
namespace Umbraco.Deploy.Infrastructure.Connectors.ServiceConnectors;

public abstract class ServiceConnectorBase<TArtifact, TUdi, TEntity> : IServiceConnector
{
    public abstract Task<TArtifact?> GetArtifactAsync(TUdi udi, IContextCache contextCache, CancellationToken cancellationToken = default);

    // Expands a selector ("this", "children", "descendants") from a picked entity into a range.
    public abstract Task<NamedUdiRange> GetRangeAsync(string entityType, string sid, string selector, IContextCache contextCache);
}
CS
  cat > $I/Trees/LegacyRemoteTreeProvider.cs <<'CS'
namespace Umbraco.Deploy.Infrastructure.Trees;

// Serves the partial restore tree for every service connector entity type that has no tree
// of its own: one node per artifact, picked with the "this" selector only.
internal sealed class LegacyRemoteTreeProvider : IRemoteTreeProvider
{
    public bool CanServe(string entityType) => !TreeRegistry.HasOwnTree(entityType);

    public Task<IEnumerable<RemoteTreeNode>> GetNodesAsync(string entityType, IServiceConnector connector)
        => connector.ListArtifactsAsync(entityType)
            .ContinueWith(t => t.Result.Select(a => new RemoteTreeNode(a.Udi, a.Name, selectors: ["this"])));
}
CS
  cat > $I/Restore/PartialRestorePickerBuilder.cs <<'CS'
namespace Umbraco.Deploy.Infrastructure.Restore;

internal sealed class PartialRestorePickerBuilder(IEnumerable<IRemoteTreeProvider> providers)
{
    public async Task<PartialRestorePicker> BuildAsync(string entityType, IServiceConnector connector)
    {
        IRemoteTreeProvider provider = providers.First(p => p.CanServe(entityType));
        return new PartialRestorePicker(await provider.GetNodesAsync(entityType, connector));
    }
}
CS
  cat > $I/Disk/DiskReader.cs <<'CS'
namespace Umbraco.Deploy.Infrastructure.Disk;

internal sealed class DiskReader
{
    public string Read(string path) => File.ReadAllText(path);
}
CS
  git add -A && git commit -qm "Deploy 18.1.0 (#2050)" && git tag release-18.1.0

  # 19 work. Each change in its own commit, the way squash merges land.
  cat > $I/Connectors/ServiceConnectors/ServiceConnectorBase.cs <<'CS'
namespace Umbraco.Deploy.Infrastructure.Connectors.ServiceConnectors;

public abstract class ServiceConnectorBase<TArtifact, TUdi, TEntity> : IServiceConnector
{
    public abstract Task<TArtifact?> GetArtifactAsync(TUdi udi, IContextCache contextCache, CancellationToken cancellationToken = default);

    // Expands a selector ("this", "children", "descendants") from a picked entity into a range.
    public abstract Task<NamedUdiRange> GetRangeAsync(string entityType, string sid, string selector, IContextCache contextCache, CancellationToken cancellationToken = default);
}
CS
  git commit -qam "Add cancellation to GetRangeAsync (#2097)"

  git rm -q $I/Trees/LegacyRemoteTreeProvider.cs
  cat > $I/Restore/PartialRestorePickerBuilder.cs <<'CS'
namespace Umbraco.Deploy.Infrastructure.Restore;

internal sealed class PartialRestorePickerBuilder(IEnumerable<IRemoteTreeProvider> providers)
{
    public async Task<PartialRestorePicker> BuildAsync(string entityType, IServiceConnector connector)
    {
        IRemoteTreeProvider? provider = providers.FirstOrDefault(p => p.CanServe(entityType));
        if (provider is not null)
        {
            return new PartialRestorePicker(await provider.GetNodesAsync(entityType, connector));
        }

        // No tree for this entity type: build the picker from the connector's own ranges.
        var roots = await connector.ListArtifactsAsync(entityType);
        var ranges = new List<NamedUdiRange>();
        foreach (var root in roots)
        {
            ranges.Add(await connector.GetRangeAsync(entityType, root.Udi.Id, "descendants", ContextCache.Empty));
        }

        return PartialRestorePicker.FromRanges(ranges);
    }
}
CS
  git add -A && git commit -qm "Remove legacy remote tree path (#2104)"

  cat > $I/Disk/DiskReader.cs <<'CS'
namespace Umbraco.Deploy.Infrastructure.Disk;

internal sealed class DiskReader(ILogger<DiskReader> logger)
{
    public string Read(string path)
    {
        logger.LogDebug("Reading {Path}", path);
        return File.ReadAllText(path);
    }
}
CS
  git commit -qam "Log disk reads at debug level (#2110)"
  git tag release-19.0.0-beta1
)

cat > CLAUDE.local.md <<'MD'
- Umbraco Deploy source: `.deploy` (a clone of umbraco/Umbraco.Deploy, tags `release-18.1.0` and `release-19.0.0-beta1`)
MD
cat > .gitignore <<'TXT'
.deploy/
CLAUDE.local.md
TXT
