#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/MyPackage/Stats src/MyPackage/Client/src/stats
cat > src/MyPackage/Stats/StatsService.cs <<'EOF'
namespace MyPackage.Stats;

internal sealed class StatsService : IStatsService
{
    private readonly IUmbracoDatabaseFactory _dbFactory;
    public StatsService(IUmbracoDatabaseFactory dbFactory) => _dbFactory = dbFactory;

    public int CountPages()
    {
        using var db = _dbFactory.CreateDatabase();
        // One row per content version that is either published or the current draft.
        return db.ExecuteScalar<int>(@"
            SELECT COUNT(*)
            FROM umbracoContentVersion v
            INNER JOIN umbracoDocumentVersion dv ON dv.id = v.id
            WHERE dv.published = 1 OR v.[current] = 1");
    }

    public int CountMedia()
    {
        using var db = _dbFactory.CreateDatabase();
        return db.ExecuteScalar<int>("SELECT COUNT(*) FROM umbracoMediaVersion");
    }
}
EOF
cat > src/MyPackage/Stats/StatsController.cs <<'EOF'
namespace MyPackage.Stats;

[VersionedApiBackOfficeRoute("my-package/stats")]
public sealed class StatsController : ManagementApiControllerBase
{
    private readonly IStatsService _stats;
    public StatsController(IStatsService stats) => _stats = stats;

    [HttpGet]
    public IActionResult Get() => Ok(new { pages = _stats.CountPages(), media = _stats.CountMedia() });
}
EOF
cat > src/MyPackage/Client/src/stats/stats-dashboard.element.ts <<'EOF'
import { html, customElement, state } from '@umbraco-cms/backoffice/external/lit';
import { UmbLitElement } from '@umbraco-cms/backoffice/lit-element';

@customElement('my-package-stats-dashboard')
export class MyPackageStatsDashboardElement extends UmbLitElement {
	@state() private _pages = 0;

	override async connectedCallback() {
		super.connectedCallback();
		const res = await fetch('/umbraco/management/api/v1/my-package/stats');
		this._pages = (await res.json()).pages;
	}

	override render() {
		return html`<uui-box headline="Stats"><p>Pages: ${this._pages}</p></uui-box>`;
	}
}
export default MyPackageStatsDashboardElement;
EOF
cat > CLAUDE.md <<'EOF'
# MyPackage

## Issue tracker

- Type: GitHub Issues
- Location: this repo, `jodean/MyPackage`
- Access: `gh`
- State labels: the defaults
EOF
cat > ISSUE-77.md <<'EOF'
# #77: Stats dashboard counts too many pages

Opened by @lee-w (not on the team). Labels: state/needs-investigation

On a site with 3 pages, where one page has an unpublished draft on top of its published
version, the stats dashboard says 4 pages.
EOF
