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
printf '\nFull docs are in the [docs](docs/) folder.\n' >> README.md
cat > Umbraco.Community.StockLevels.slnx <<'X'
<Solution>
  <Project Path="src/Umbraco.Community.StockLevels/Umbraco.Community.StockLevels.csproj" />
</Solution>
X
printf 'bin/\nobj/\nnode_modules/\n' > .gitignore
mkdir -p .claude/memory docs/plans
printf '# Memory\n\nOne file per entry.\n' > .claude/memory/README.md
printf '# Memory index\n' > .claude/memory/MEMORY.md
touch docs/plans/.gitkeep
cat > CLAUDE.md <<'MD'
# Umbraco.Community.StockLevels

Track stock per product in the Umbraco backoffice.

## Stack

- Umbraco CMS: 17
- Database: SQL Server + SQLite

## Build & test

```bash
dotnet build Umbraco.Community.StockLevels.slnx
dotnet test Umbraco.Community.StockLevels.slnx
```

## Feature workflow

This project uses the Umbraco Devkit. Feature plan folders live at:
`docs/plans/<feature-slug>/`

## Conventions

- File-scoped namespaces everywhere.
MD
