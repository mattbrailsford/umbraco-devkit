#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.Redirects

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`. Other
packages and sites call `RedirectService` directly.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`, and a
branch named after the slug.
EOF
P=docs/plans/bulk-delete
mkdir -p "$P/mockups" "$P/screenshots" src/Redirects/Api src/Redirects/Services src/Client/src/dashboard
printf 'PNG' > "$P/mockups/redirects-dashboard.png"
cat > src/Redirects/Services/RedirectService.cs <<'EOF'
namespace Umbraco.Community.Redirects.Services;

public class RedirectService(IRedirectRepository repository)
{
    public Task<PagedResult<Redirect>> GetPageAsync(int skip, int take) => repository.GetPageAsync(skip, take);

    public Task DeleteAsync(Guid key) => repository.DeleteAsync(key);
}
EOF
cat > src/Redirects/Api/RedirectsController.cs <<'EOF'
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Umbraco.Cms.Web.Common.Authorization;

namespace Umbraco.Community.Redirects.Api;

[ApiExplorerSettings(GroupName = "Redirects")]
[Authorize(Policy = AuthorizationPolicies.SectionAccessSettings)]
public class RedirectsController(RedirectService service) : RedirectsControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get(int skip = 0, int take = 20) => Ok(await service.GetPageAsync(skip, take));

    [HttpDelete("{key:guid}")]
    public async Task<IActionResult> Delete(Guid key)
    {
        await service.DeleteAsync(key);
        return Ok();
    }
}
EOF
cat > src/Client/src/dashboard/redirects-dashboard.element.ts <<'EOF'
import { html, customElement, state } from '@umbraco-cms/backoffice/external/lit';
import { UmbLitElement } from '@umbraco-cms/backoffice/lit-element';
import { RedirectsRepository, type RedirectModel } from '../repository/redirects.repository.js';

@customElement('redirects-dashboard')
export class RedirectsDashboardElement extends UmbLitElement {
	#repository = new RedirectsRepository(this);
	@state() private _items: Array<RedirectModel> = [];

	override render() {
		return html`
			<uui-box headline="Redirects">
				<uui-table>
					${this._items.map((r) => html`<uui-table-row><uui-table-cell>${r.from}</uui-table-cell><uui-table-cell>${r.to}</uui-table-cell></uui-table-row>`)}
				</uui-table>
			</uui-box>
		`;
	}
}
EOF
cat > "$P/README.md" <<'EOF'
# Bulk delete redirects

1. [x] [BRIEF.md](./BRIEF.md) — editors can't clear out hundreds of stale redirects
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — one bulk endpoint, selection in the dashboard
3. [x] [SPEC.md](./SPEC.md) — select, confirm, delete
4. [x] [STORIES.md](./STORIES.md) — two stories
5. [x] [PLAN.md](./PLAN.md) — four tasks
6. [x] [BUILD-LOG.md](./BUILD-LOG.md) — four tasks, four commits

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
EOF
cat > "$P/BRIEF.md" <<'EOF'
# Bulk delete: brief

Sites that migrated from v8 have hundreds of stale redirects. Editors delete them one at a
time today. They want to select many and delete them in one go, without risk of wiping
redirects they still need.
EOF
cat > "$P/ARCHITECTURE.md" <<'EOF'
# Bulk delete: architecture

- New Management API endpoint `POST /redirects/bulk-delete` taking a list of keys.
- `RedirectService.DeleteManyAsync(keys)` deletes in one database round trip.
- Dashboard gets row selection (uui-table selectable) and a "Delete selected" button in the
  box header, as in `mockups/redirects-dashboard.png`.
- Same access rule as the existing dashboard: Settings section.
EOF
cat > "$P/SPEC.md" <<'EOF'
# Bulk delete: spec

- Rows in the redirects table can be selected; a header checkbox selects the current page.
- A "Delete selected" button in the box header is disabled until at least one row is
  selected.
- Clicking it opens a confirm dialog: "Delete N redirects?" with Delete / Cancel.
- On Delete, the selected redirects are removed, the table refreshes, and a notification
  says how many were deleted.
- Only users with access to the Settings section can bulk delete.

## Management API surface
`POST /umbraco/redirects/api/v1/bulk-delete` body `{ keys: Guid[] }` → 200.

## Frontend components
`redirects-dashboard` gains selection and the header button.
EOF
cat > "$P/STORIES.md" <<'EOF'
# Bulk delete: stories
1. Select several redirects. 2. Delete them after confirming.
EOF
cat > "$P/PLAN.md" <<'EOF'
# Bulk delete: plan

- [x] Add `DeleteManyAsync` to the repository and service.
- [x] Add the bulk-delete endpoint.
- [x] Add row selection and the header checkbox to the dashboard.
- [x] Add the button, confirm dialog and notification.
EOF
cat > "$P/DECISION-LOG.md" <<'EOF'
# Bulk delete: decision log

- 2026-10-01 (feature-design): Header checkbox selects the current page only, not every
  redirect. The user chose it to avoid deleting thousands by accident.
- 2026-10-14 (feature-build, task 1): Added the Polly package to retry a delete that hits a
  database deadlock.
- 2026-10-15 (feature-build, task 3): Used `uui-table` `selectable` attribute rather than a
  checkbox cell per row.
- 2026-10-16 (feature-build, task 4): Used icon `icon-trash` on the button.
EOF
cat > "$P/BUILD-LOG.md" <<'EOF'
# Bulk delete: build log

- Task 1 — `a1a1a1a` — DeleteManyAsync; unit test `DeleteMany_removes_all_given_keys`.
- Task 2 — `b2b2b2b` — bulk-delete endpoint; integration test `BulkDelete_returns_ok`.
- Task 3 — `c3c3c3c` — row selection and header checkbox. Click path: Settings › Redirects.
  Screenshot [redirects-dashboard.png](./screenshots/redirects-dashboard.png) (before:
  [redirects-dashboard-before.png](./screenshots/redirects-dashboard-before.png)).
- Task 4 — `d4d4d4d` — button, confirm dialog, notification.
EOF
git add -A && git commit -qm "docs: add plan folder for bulk-delete"

# ---- the feature branch's changes ----
printf 'PNG' > "$P/screenshots/redirects-dashboard.png"
printf 'PNG' > "$P/screenshots/redirects-dashboard-before.png"
mkdir -p src/Redirects/Migrations src/Redirects/Notifications src/Redirects/Composing tests/Redirects.Tests src/Client/src/repository
cat > src/Redirects/Services/IRedirectService.cs <<'EOF'
namespace Umbraco.Community.Redirects.Services;

public interface IRedirectService
{
    Task<PagedResult<Redirect>> GetPageAsync(int skip, int take);
    Task DeleteAsync(Guid key);
    Task<int> DeleteManyAsync(IReadOnlyCollection<Guid> keys);
}
EOF
cat > src/Redirects/Services/RedirectService.cs <<'EOF'
using Polly;

namespace Umbraco.Community.Redirects.Services;

internal sealed class RedirectService(IRedirectRepository repository, IDeletedRedirectArchive archive) : IRedirectService
{
    private static readonly AsyncPolicy Retry = Policy.Handle<DbDeadlockException>().RetryAsync(3);

    public Task<PagedResult<Redirect>> GetPageAsync(int skip, int take) => repository.GetPageAsync(skip, take);

    public Task DeleteAsync(Guid key) => repository.DeleteAsync(key);

    public async Task<int> DeleteManyAsync(IReadOnlyCollection<Guid> keys)
    {
        var redirects = await repository.GetManyAsync(keys);
        await archive.AddAsync(redirects);
        return await Retry.ExecuteAsync(() => repository.DeleteManyAsync(keys));
    }
}
EOF
cat > src/Redirects/Services/DeletedRedirectArchive.cs <<'EOF'
using Umbraco.Cms.Infrastructure.Scoping;

namespace Umbraco.Community.Redirects.Services;

public interface IDeletedRedirectArchive
{
    Task AddAsync(IEnumerable<Redirect> redirects);
}

// Keeps a copy of every bulk-deleted redirect.
internal sealed class DeletedRedirectArchive(IScopeProvider scopeProvider) : IDeletedRedirectArchive
{
    public async Task AddAsync(IEnumerable<Redirect> redirects)
    {
        using var scope = scopeProvider.CreateScope();
        foreach (var r in redirects)
        {
            await scope.Database.InsertAsync(new DeletedRedirectDto { Key = r.Key, From = r.From, To = r.To, DeletedUtc = DateTime.UtcNow });
        }
        scope.Complete();
    }
}
EOF
cat > src/Redirects/Migrations/AddDeletedRedirectsTable.cs <<'EOF'
using Umbraco.Cms.Infrastructure.Migrations;

namespace Umbraco.Community.Redirects.Migrations;

public class AddDeletedRedirectsTable(IMigrationContext context) : MigrationBase(context)
{
    protected override void Migrate()
    {
        if (!TableExists("redirectsDeleted"))
        {
            Create.Table<DeletedRedirectDto>().Do();
        }
    }
}
EOF
cat > src/Redirects/Notifications/DeleteRedirectsForDeletedContent.cs <<'EOF'
using Umbraco.Cms.Core.Events;
using Umbraco.Cms.Core.Notifications;

namespace Umbraco.Community.Redirects.Notifications;

// Bulk delete makes stale redirects cheap to clear, so clear them as content goes.
internal sealed class DeleteRedirectsForDeletedContent(IRedirectRepository repository, IRedirectService service)
    : INotificationAsyncHandler<ContentDeletedNotification>
{
    public async Task HandleAsync(ContentDeletedNotification notification, CancellationToken cancellationToken)
    {
        var keys = await repository.GetKeysTargetingAsync(notification.DeletedEntities.Select(e => e.Key));
        await service.DeleteManyAsync(keys);
    }
}
EOF
cat > src/Redirects/Composing/RedirectsComposer.cs <<'EOF'
using Umbraco.Cms.Core.Composing;
using Umbraco.Cms.Core.DependencyInjection;
using Umbraco.Cms.Core.Notifications;

namespace Umbraco.Community.Redirects.Composing;

public class RedirectsComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder)
    {
        builder.Services.AddScoped<IRedirectService, RedirectService>();
        builder.Services.AddScoped<IDeletedRedirectArchive, DeletedRedirectArchive>();
        builder.AddNotificationAsyncHandler<ContentDeletedNotification, DeleteRedirectsForDeletedContent>();
        builder.PackageMigrationPlans().Add<RedirectsMigrationPlan>();
    }
}
EOF
cat > src/Redirects/Api/RedirectsController.cs <<'EOF'
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Umbraco.Cms.Web.Common.Authorization;

namespace Umbraco.Community.Redirects.Api;

[ApiExplorerSettings(GroupName = "Redirects")]
[Authorize(Policy = AuthorizationPolicies.SectionAccessSettings)]
public class RedirectsController(IRedirectService service) : RedirectsControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get(int skip = 0, int take = 20) => Ok(await service.GetPageAsync(skip, take));

    [HttpDelete("{key:guid}")]
    public async Task<IActionResult> Delete(Guid key)
    {
        await service.DeleteAsync(key);
        return Ok();
    }

    [HttpPost("bulk-delete")]
    public async Task<IActionResult> BulkDelete(BulkDeleteRequest request)
    {
        await service.DeleteManyAsync(request.Keys);
        return Ok();
    }
}

public record BulkDeleteRequest(Guid[] Keys);
EOF
cat > tests/Redirects.Tests/RedirectServiceTests.cs <<'EOF'
using NSubstitute;

public class RedirectServiceTests
{
    [Fact]
    public async Task DeleteMany_removes_all_given_keys()
    {
        var repository = Substitute.For<IRedirectRepository>();
        var keys = new[] { Guid.NewGuid(), Guid.NewGuid() };
        repository.DeleteManyAsync(keys).Returns(2);
        var service = new RedirectService(repository, Substitute.For<IDeletedRedirectArchive>());

        Assert.Equal(2, await service.DeleteManyAsync(keys));
    }
}
EOF
cat > tests/Redirects.Tests/RedirectsApiTests.cs <<'EOF'
public class RedirectsApiTests(RedirectsApiFactory factory) : IClassFixture<RedirectsApiFactory>
{
    [Fact]
    public async Task BulkDelete_returns_ok()
    {
        var client = await factory.CreateSettingsUserClientAsync();
        var response = await client.PostAsJsonAsync("/umbraco/redirects/api/v1/bulk-delete", new { keys = new[] { Guid.NewGuid() } });
        response.EnsureSuccessStatusCode();
    }
}
EOF
cat > src/Client/src/repository/redirects.repository.ts <<'EOF'
import { UmbControllerBase } from '@umbraco-cms/backoffice/class-api';
import { tryExecute } from '@umbraco-cms/backoffice/resources';
import { RedirectsService } from '../api/sdk.gen.js';

export type RedirectModel = { key: string; from: string; to: string };

export class RedirectsRepository extends UmbControllerBase {
	async getPage(skip: number, take: number) {
		const { data } = await tryExecute(this, RedirectsService.getRedirects({ query: { skip, take } }));
		return { items: (data?.items ?? []) as RedirectModel[] };
	}

	async bulkDelete(keys: string[]) {
		return tryExecute(this, RedirectsService.postRedirectsBulkDelete({ body: { keys } }));
	}
}
EOF
cat > src/Client/src/dashboard/redirects-dashboard.element.ts <<'EOF'
import { html, customElement, state } from '@umbraco-cms/backoffice/external/lit';
import { UmbLitElement } from '@umbraco-cms/backoffice/lit-element';
import { umbConfirmModal } from '@umbraco-cms/backoffice/modal';
import { UMB_NOTIFICATION_CONTEXT } from '@umbraco-cms/backoffice/notification';
import { RedirectsRepository, type RedirectModel } from '../repository/redirects.repository.js';

@customElement('redirects-dashboard')
export class RedirectsDashboardElement extends UmbLitElement {
	#repository = new RedirectsRepository(this);
	@state() private _items: Array<RedirectModel> = [];
	@state() private _selection: Array<string> = [];

	override connectedCallback() {
		super.connectedCallback();
		this.#load();
	}

	async #load() {
		this._items = (await this.#repository.getPage(0, 20)).items;
	}

	#onDelete = async () => {
		const n = this._selection.length;
		try {
			await umbConfirmModal(this, { headline: `Delete ${n} redirects?`, content: '', color: 'danger', confirmLabel: 'Delete' });
		} catch {
			return;
		}
		await this.#repository.bulkDelete(this._selection);
		const notifications = await this.getContext(UMB_NOTIFICATION_CONTEXT);
		notifications?.peek('positive', { data: { message: `${n} redirects deleted` } });
		this._selection = [];
		await this.#load();
	};

	#togglePage = (e: Event) => {
		this._selection = (e.target as HTMLInputElement).checked ? this._items.map((r) => r.key) : [];
	};

	override render() {
		return html`
			<uui-box headline="Redirects">
				<uui-table>
					<uui-table-head>
						<uui-table-head-cell><uui-checkbox label="Select page" @change=${this.#togglePage}></uui-checkbox></uui-table-head-cell>
						<uui-table-head-cell>From</uui-table-head-cell><uui-table-head-cell>To</uui-table-head-cell>
					</uui-table-head>
					${this._items.map(
						(r) => html`<uui-table-row selectable ?selected=${this._selection.includes(r.key)}
							@selected=${() => (this._selection = [...this._selection, r.key])}
							@deselected=${() => (this._selection = this._selection.filter((k) => k !== r.key))}>
							<uui-table-cell>${r.from}</uui-table-cell><uui-table-cell>${r.to}</uui-table-cell>
						</uui-table-row>`,
					)}
				</uui-table>
				<uui-button look="primary" color="danger" label="Remove" ?disabled=${!this._selection.length} @click=${this.#onDelete}>
					<uui-icon name="icon-trash"></uui-icon> Remove
				</uui-button>
			</uui-box>
		`;
	}
}
EOF
# git can't run inside the eval sandbox, so hand over the branch diff as a file.
git add -A && git diff --cached > CHANGE.diff && git reset -q --hard
cat > COMMITS.txt <<'EOF'
d4d4d4d feat(bulk-delete): add the button, confirm dialog and notification
c3c3c3c feat(bulk-delete): add row selection and the page checkbox
b2b2b2b feat(bulk-delete): add the bulk-delete endpoint
a1a1a1a feat(bulk-delete): add DeleteManyAsync
EOF
