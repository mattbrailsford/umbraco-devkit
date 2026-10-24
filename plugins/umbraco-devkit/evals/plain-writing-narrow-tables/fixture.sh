#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/Controllers docs
cat > src/Controllers/StockController.cs <<'CS'
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Umbraco.Cms.Api.Management.Controllers;
using Umbraco.Cms.Web.Common.Authorization;

namespace Acme.Stock.Controllers;

// Base route: /umbraco/management/api/v1/acme-stock
[ApiVersion("1.0")]
[VersionedApiBackOfficeRoute("acme-stock")]
[ApiExplorerSettings(GroupName = "Acme Stock")]
public class StockController : ManagementApiControllerBase
{
    // Lists stock levels, paged. skip >= 0, take 1-200 (default 50).
    // 200: { total: int, items: [{ productKey: Guid, sku: string, level: int, reserved: int, updatedUtc: DateTime }] }
    // 400 ProblemDetails when take is out of range.
    [HttpGet("levels")]
    [Authorize(Policy = AuthorizationPolicies.SectionAccessContent)]
    public Task<IActionResult> GetLevels(int skip = 0, int take = 50) => throw null!;

    // One product's level. 200 as one item above. 404 when the product has no stock record.
    [HttpGet("levels/{productKey:guid}")]
    [Authorize(Policy = AuthorizationPolicies.SectionAccessContent)]
    public Task<IActionResult> GetLevel(Guid productKey) => throw null!;

    // Sets a level. Body: { level: int (>= 0), reason: string (max 200 chars) }.
    // 204 on success. 400 ProblemDetails for a negative level or a long reason.
    // 404 when the product doesn't exist. 409 when reserved > new level.
    [HttpPut("levels/{productKey:guid}")]
    [Authorize(Policy = AuthorizationPolicies.SectionAccessSettings)]
    public Task<IActionResult> SetLevel(Guid productKey, SetLevelRequest body) => throw null!;

    // Reserves stock for an order. Body: { orderId: string, quantity: int (1-1000) }.
    // 200: { reservationId: Guid, expiresUtc: DateTime } (reservations expire after 15 minutes).
    // 409 when quantity > level - reserved. 404 when the product doesn't exist.
    [HttpPost("levels/{productKey:guid}/reservations")]
    [Authorize(Policy = AuthorizationPolicies.SectionAccessContent)]
    public Task<IActionResult> Reserve(Guid productKey, ReserveRequest body) => throw null!;
}
CS
