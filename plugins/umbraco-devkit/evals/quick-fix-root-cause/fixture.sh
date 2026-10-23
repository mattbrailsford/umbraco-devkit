#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/MyShop/Orders src/MyShop/Checkout src/MyShop/Api src/MyShop/Loyalty
cat > src/MyShop/Orders/Order.cs <<'CS'
namespace MyShop.Orders;

public sealed class Order
{
    public Guid Key { get; set; }
    public string Number { get; set; } = string.Empty;
    public Customer Customer { get; set; } = null!;
    public IList<OrderLine> Lines { get; set; } = new List<OrderLine>();
    public decimal Total => Lines.Sum(l => l.Price * l.Quantity);
    public DateTime PlacedUtc { get; set; }
}

public sealed class Customer
{
    public Guid Key { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}

public sealed record OrderLine(string Sku, string Name, decimal Price, int Quantity);
CS
cat > src/MyShop/Checkout/CheckoutService.cs <<'CS'
using MyShop.Orders;

namespace MyShop.Checkout;

internal sealed class CheckoutService : ICheckoutService
{
    private readonly IOrderRepository _orders;
    private readonly ICustomerRepository _customers;
    private readonly IOrderNotifier _notifier;

    public CheckoutService(IOrderRepository orders, ICustomerRepository customers, IOrderNotifier notifier)
    {
        _orders = orders;
        _customers = customers;
        _notifier = notifier;
    }

    public async Task<Order> PlaceOrderAsync(Cart cart, Guid customerKey)
    {
        var order = NewOrder(cart);
        order.Customer = await _customers.GetAsync(customerKey);
        await _orders.SaveAsync(order);
        await _notifier.OrderPlacedAsync(order);
        return order;
    }

    public async Task<Order> PlaceGuestOrderAsync(Cart cart, string email)
    {
        var order = NewOrder(cart);
        await _orders.SaveAsync(order);
        await _notifier.OrderPlacedAsync(order);
        return order;
    }

    private static Order NewOrder(Cart cart) => new()
    {
        Key = Guid.NewGuid(),
        Number = OrderNumber.Next(),
        Lines = cart.Lines.Select(l => new OrderLine(l.Sku, l.Name, l.Price, l.Quantity)).ToList(),
        PlacedUtc = DateTime.UtcNow,
    };
}
CS
cat > src/MyShop/Orders/OrderEmailBuilder.cs <<'CS'
namespace MyShop.Orders;

internal sealed class OrderEmailBuilder
{
    public OrderEmail Build(Order order) => new(
        To: order.Customer.Email,
        Subject: $"Order {order.Number} confirmed",
        Body: $"Hi {order.Customer.Name},\n\nThanks for your order of {order.Lines.Count} items, total {order.Total:C}.");
}

public sealed record OrderEmail(string To, string Subject, string Body);
CS
cat > src/MyShop/Orders/OrderNotifier.cs <<'CS'
namespace MyShop.Orders;

internal sealed class OrderNotifier : IOrderNotifier
{
    private readonly OrderEmailBuilder _builder;
    private readonly IEmailSender _sender;

    public OrderNotifier(OrderEmailBuilder builder, IEmailSender sender)
    {
        _builder = builder;
        _sender = sender;
    }

    public Task OrderPlacedAsync(Order order) => _sender.SendAsync(_builder.Build(order));
}
CS
cat > src/MyShop/Orders/OrderExportService.cs <<'CS'
using System.Text;

namespace MyShop.Orders;

internal sealed class OrderExportService
{
    public string ToCsv(IEnumerable<Order> orders)
    {
        var sb = new StringBuilder("Number,Customer,Email,Total,Placed\n");
        foreach (var o in orders)
            sb.AppendLine($"{o.Number},{o.Customer.Name},{o.Customer.Email},{o.Total},{o.PlacedUtc:O}");
        return sb.ToString();
    }
}
CS
cat > src/MyShop/Api/OrdersApiController.cs <<'CS'
using Microsoft.AspNetCore.Mvc;
using MyShop.Orders;

namespace MyShop.Api;

[ApiController]
[Route("umbraco/myshop/api/v1/orders")]
public sealed class OrdersApiController : ControllerBase
{
    private readonly IOrderRepository _orders;
    public OrdersApiController(IOrderRepository orders) => _orders = orders;

    [HttpGet]
    public async Task<IActionResult> List(int skip = 0, int take = 50)
    {
        var page = await _orders.GetPageAsync(skip, take);
        return Ok(page.Select(o => new
        {
            o.Key,
            o.Number,
            CustomerName = o.Customer.Name,
            o.Total,
            o.PlacedUtc,
        }));
    }
}
CS
cat > src/MyShop/Loyalty/LoyaltyPointsHandler.cs <<'CS'
using MyShop.Orders;

namespace MyShop.Loyalty;

internal sealed class LoyaltyPointsHandler : IOrderPlacedHandler
{
    private readonly ILoyaltyLedger _ledger;
    public LoyaltyPointsHandler(ILoyaltyLedger ledger) => _ledger = ledger;

    public Task HandleAsync(Order order)
        => _ledger.AddAsync(order.Customer.Key, (int)Math.Floor(order.Total));
}
CS
