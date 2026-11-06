#!/usr/bin/env bash
set -euo pipefail
P=src/Umbraco.Community.ProductFinder
mkdir -p $P/Search $P/Composing tests/Umbraco.Community.ProductFinder.Tests
cat > CLAUDE.md <<'MD'
# Umbraco.Community.ProductFinder

An Umbraco 18 package: a product search for the website, built on the CMS's search. One
version line: `main`. The package version follows the CMS major (18.x for Umbraco 18).
MD
cat > $P/Umbraco.Community.ProductFinder.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Version>18.1.0</Version>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" Version="[18.2.0, 19.0.0)" />
    <PackageReference Include="Umbraco.Cms.Examine.Lucene" Version="[18.2.0, 19.0.0)" />
  </ItemGroup>
</Project>
XML
cat > $P/Search/ProductSearchService.cs <<'CS'
using Examine;
using Examine.Search;
using Umbraco.Cms.Core;

namespace Umbraco.Community.ProductFinder.Search;

public sealed class ProductSearchService(IExamineManager examineManager) : IProductSearchService
{
    public IReadOnlyList<ProductHit> Search(string text, string culture, int take = 20)
    {
        if (!examineManager.TryGetIndex(Constants.UmbracoIndexes.ExternalIndexName, out var index))
            return [];

        var results = index.Searcher.CreateQuery("content")
            .NodeTypeAlias("product")
            .And().ManagedQuery(text, [$"nodeName_{culture.ToLowerInvariant()}", "sku", "description"])
            .Execute(QueryOptions.SkipTake(0, take));

        return results.Select(r => new ProductHit(Guid.Parse(r["__Key"]), r[$"nodeName_{culture.ToLowerInvariant()}"], r.Score)).ToList();
    }
}
CS
cat > $P/Search/IProductSearchService.cs <<'CS'
namespace Umbraco.Community.ProductFinder.Search;

public interface IProductSearchService
{
    IReadOnlyList<ProductHit> Search(string text, string culture, int take = 20);
}

public sealed record ProductHit(Guid Key, string Name, float Score);
CS
cat > $P/Search/ProductValueSetBuilder.cs <<'CS'
using Examine;
using Umbraco.Cms.Core.Events;
using Umbraco.Cms.Infrastructure.Examine;

namespace Umbraco.Community.ProductFinder.Search;

// Adds the product SKU as its own field so it can be searched exactly.
internal sealed class ProductIndexingHandler : INotificationHandler<UmbracoExamineIndexingNotification>
{
    public void Handle(UmbracoExamineIndexingNotification notification) { /* adds "sku" */ }
}
CS
cat > $P/Composing/ProductFinderComposer.cs <<'CS'
using Umbraco.Cms.Core.Composing;
using Umbraco.Cms.Core.DependencyInjection;
using Umbraco.Community.ProductFinder.Search;

namespace Umbraco.Community.ProductFinder.Composing;

internal sealed class ProductFinderComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder)
    {
        builder.Services.AddScoped<IProductSearchService, ProductSearchService>();
        builder.AddNotificationHandler<UmbracoExamineIndexingNotification, ProductIndexingHandler>();
    }
}
CS
