#!/usr/bin/env bash
set -euo pipefail
d=src/Umbraco.Community.Items
mkdir -p $d/Services
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.Items

An Umbraco package on NuGet. One branch per CMS major; the package major tracks the CMS major:

| Branch | CMS | Package | Status |
|---|---|---|---|
| `v17/main` | 17 | 4.x | released |
| `v18/main` (this checkout) | 18 | 5.x | released |
| `v19/main` | 19.0.0-beta1 | 6.0.0-beta1 | pre-release on NuGet; CMS 19 final isn't out yet |

Fixes and features land on every line.
EOF
cat > $d/Umbraco.Community.Items.csproj <<'EOF'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <PackageId>Umbraco.Community.Items</PackageId>
    <Version>5.2.0</Version>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" Version="[18.0.0, 19)" />
  </ItemGroup>
</Project>
EOF
cat > $d/Services/Item.cs <<'EOF'
namespace Umbraco.Community.Items.Services;

public sealed record Item(Guid Id, string Name, IReadOnlyList<string> Tags, bool IsArchived);
EOF
cat > $d/Services/ItemOptions.cs <<'EOF'
namespace Umbraco.Community.Items.Services;

public sealed class ItemOptions
{
    public static ItemOptions Default { get; } = new();

    /// <summary>Return the item even when it's archived.</summary>
    public bool IncludeArchived { get; init; }

    /// <summary>Skip loading tags, for callers that only need the name.</summary>
    public bool SkipTags { get; init; }
}
EOF
cat > $d/Services/ItemService.cs <<'EOF'
using Umbraco.Community.Items.Persistence;

namespace Umbraco.Community.Items.Services;

public class ItemService(IItemRepository repository)
{
    public async Task<Item?> GetItemAsync(Guid id)
    {
        ItemRow? row = await repository.GetAsync(id);
        if (row is null || row.IsArchived)
        {
            return null;
        }

        IReadOnlyList<string> tags = await repository.GetTagsAsync(id);
        return new Item(row.Id, row.Name, tags, row.IsArchived);
    }
}
EOF
mkdir -p $d/Persistence
cat > $d/Persistence/IItemRepository.cs <<'EOF'
namespace Umbraco.Community.Items.Persistence;

public sealed record ItemRow(Guid Id, string Name, bool IsArchived);

public interface IItemRepository
{
    Task<ItemRow?> GetAsync(Guid id);
    Task<IReadOnlyList<string>> GetTagsAsync(Guid id);
}
EOF
