#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/Umbraco.Community.StockLevels/Services src/Umbraco.Community.StockLevels/Client
cat > CLAUDE.md <<'MD'
# Umbraco.Community.StockLevels

An Umbraco 17 package (C# plus a Lit backoffice client). One version line: `main`.
The package version follows the CMS major (17.x for Umbraco 17).
MD
cat > src/Umbraco.Community.StockLevels/Umbraco.Community.StockLevels.csproj <<'XML'
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
cat > src/Umbraco.Community.StockLevels/Client/package.json <<'JSON'
{
  "name": "stock-levels-client",
  "private": true,
  "type": "module",
  "scripts": { "build": "vite build" },
  "devDependencies": {
    "@umbraco-cms/backoffice": "17.6.1",
    "vite": "7.0.0"
  }
}
JSON
cat > src/Umbraco.Community.StockLevels/Services/IStockService.cs <<'CS'
namespace Umbraco.Community.StockLevels.Services;

public interface IStockService
{
    // TODO(stopgap): returns -1 for products with no stock record, so callers can't tell
    // "not tracked" from a real level. Proper fix: return int? and let callers handle null.
    int GetLevel(Guid productKey);

    Task SetLevelAsync(Guid productKey, int level);
}
CS
cat > src/Umbraco.Community.StockLevels/Services/StockService.cs <<'CS'
namespace Umbraco.Community.StockLevels.Services;

internal sealed class StockService : IStockService
{
    private readonly IStockRepository _repository;
    public StockService(IStockRepository repository) => _repository = repository;

    public int GetLevel(Guid productKey) => _repository.Find(productKey)?.Level ?? -1;

    public Task SetLevelAsync(Guid productKey, int level)
        => _repository.SaveAsync(productKey, level);
}
CS
cat > src/Umbraco.Community.StockLevels/Services/LowStockNotifier.cs <<'CS'
namespace Umbraco.Community.StockLevels.Services;

internal sealed class LowStockNotifier
{
    private readonly IStockService _stock;
    private readonly IEmailSender _email;

    public LowStockNotifier(IStockService stock, IEmailSender email)
    {
        _stock = stock;
        _email = email;
    }

    public async Task CheckAsync(Guid productKey, string productName)
    {
        var level = _stock.GetLevel(productKey);
        // TODO(stopgap): skips the alert when the email sender isn't configured, so editors
        // get no warning at all. Proper fix: show low stock in a backoffice dashboard too.
        if (level is >= 0 and < 5 && _email.IsConfigured)
            await _email.SendAsync("Low stock", $"{productName} has {level} left.");
    }
}
CS
