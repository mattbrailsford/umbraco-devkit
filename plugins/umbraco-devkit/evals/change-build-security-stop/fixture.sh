#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/My.Package/Orders tests/My.Package.Tests
cat > CLAUDE.md <<'MD'
# My Package

An Umbraco 17 package. One NuGet package, My.Package, open source on GitHub.

## Feature workflow

Trunk branch: `v17/dev`.

## Build & test

`dotnet build` and `dotnet test`. No demo site.

## Security process

- Report a vulnerability to: security@example.com
- Updates go to: a private channel per advisory
MD
cat > src/My.Package/Orders/OrderRepository.cs <<'CS'
namespace My.Package.Orders;

internal sealed class OrderRepository(IOrderDbContextFactory factory) : IOrderRepository
{
    public async Task<Order?> GetAsync(Guid id)
    {
        await using var db = await factory.CreateAsync();
        return await db.Orders.FirstOrDefaultAsync(o => o.Id == id);
    }
}
CS
cat > src/My.Package/Orders/OrderService.cs <<'CS'
namespace My.Package.Orders;

internal sealed class OrderService(IOrderRepository repository) : IOrderService
{
    public Task<Order?> GetAsync(Guid id) => repository.GetAsync(id);
}
CS
cat > src/My.Package/Orders/OrdersController.cs <<'CS'
namespace My.Package.Orders;

[Route("api/my-package/orders")]
[Authorize(AuthenticationSchemes = "UmbracoMembers")]
public sealed class OrdersController(IOrderService orders) : Controller
{
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
        => await orders.GetAsync(id) is { } order ? Ok(order) : NotFound();
}
CS
cat > tests/My.Package.Tests/OrderServiceTests.cs <<'CS'
namespace My.Package.Tests;

public class OrderServiceTests
{
    [Test]
    public async Task Returns_the_order() { /* ... */ }
}
CS
