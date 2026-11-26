#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/My.Package/Controllers/Webhooks
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
cat > src/My.Package/Controllers/Webhooks/GetWebhooksController.cs <<'CS'
namespace My.Package.Controllers.Webhooks;

[VersionedApiBackOfficeRoute("my-package/webhooks")]
[ApiExplorerSettings(GroupName = "My Package")]
[Authorize(Policy = AuthorizationPolicies.SectionAccessSettings)]
public sealed class GetWebhooksController(IWebhookStore store) : ManagementApiControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get() => Ok(await store.GetAllAsync());
}
CS
cat > src/My.Package/Controllers/Webhooks/DeleteWebhookController.cs <<'CS'
namespace My.Package.Controllers.Webhooks;

[VersionedApiBackOfficeRoute("my-package/webhooks")]
[ApiExplorerSettings(GroupName = "My Package")]
public sealed class DeleteWebhookController(IWebhookStore store) : ManagementApiControllerBase
{
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await store.DeleteAsync(id);
        return Ok();
    }
}
CS
