#!/usr/bin/env bash
set -euo pipefail
P=src/Umbraco.Community.StockLevels
mkdir -p $P/Services
cat > README.md <<'MD'
# Stock Levels

Track stock per product in the Umbraco backoffice. Works with Umbraco 17.
MD
cat > $P/Umbraco.Community.StockLevels.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Version>17.2.0</Version>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" Version="[17.6.1, 18.0.0)" />
  </ItemGroup>
</Project>
XML
cat > $P/Services/IStockService.cs <<'CS'
namespace Umbraco.Community.StockLevels.Services;

public interface IStockService
{
    [Obsolete("Use GetLevelAsync. Scheduled for removal in v18.")]
    int GetLevel(Guid productKey);

    Task<int?> GetLevelAsync(Guid productKey);

    Task SetLevelAsync(Guid productKey, int level);
}
CS
cat > $P/Services/StockService.cs <<'CS'
namespace Umbraco.Community.StockLevels.Services;

internal sealed class StockService : IStockService
{
    private readonly IStockRepository _repository;
    public StockService(IStockRepository repository) => _repository = repository;

    [Obsolete("Use GetLevelAsync. Scheduled for removal in v18.")]
    public int GetLevel(Guid productKey) => GetLevelAsync(productKey).GetAwaiter().GetResult() ?? -1;

    public async Task<int?> GetLevelAsync(Guid productKey)
        => (await _repository.FindAsync(productKey))?.Level;

    public Task SetLevelAsync(Guid productKey, int level)
        => _repository.SaveAsync(productKey, level);
}
CS
write_docs() {
mkdir -p "$1"
cat > "$1/installation.md" <<'MD'
# Installation

Requires Umbraco 17 and .NET 10.

```bash
dotnet add package Umbraco.Community.StockLevels
```
MD
cat > "$1/usage.md" <<'MD'
# Reading stock in code

Inject `IStockService` and read a product's level:

```csharp
var level = _stockService.GetLevel(product.Key);
```
MD
cat > "$1/dashboard.md" <<'MD'
# The Stock dashboard

Open the **Content** section and pick the **Stock** tab. Edit a level in place and press
**Save**.
MD
}
write_docs docs
cat > CLAUDE.md <<'MD'
# Umbraco.Community.StockLevels

An Umbraco 17 package (C# plus a Lit backoffice client). One version line: `main`.
The package version follows the CMS major (17.x for Umbraco 17).

## Docs

- Where: `docs/` in this repo
- Versions: one copy for every version
- Submitting: in the same PR as the code
MD
