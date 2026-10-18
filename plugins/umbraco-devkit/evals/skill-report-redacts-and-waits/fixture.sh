#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/Hansen.Bookings/Pricing
cat > src/Hansen.Bookings/Hansen.Bookings.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup><TargetFramework>net10.0</TargetFramework></PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" Version="17.2.1" />
  </ItemGroup>
</Project>
XML
cat > src/Hansen.Bookings/Pricing/PriceCache.cs <<'CS'
namespace Hansen.Bookings.Pricing;

// Prices change when an editor publishes a Tour node. The cache is cleared from a
// ContentPublishedNotification handler.
internal sealed class PriceCache(IAppPolicyCache runtimeCache)
{
    public decimal? Get(int tourId) => runtimeCache.GetCacheItem<decimal?>($"price-{tourId}");
    public void Clear(int tourId) => runtimeCache.ClearByKey($"price-{tourId}");
}
CS
