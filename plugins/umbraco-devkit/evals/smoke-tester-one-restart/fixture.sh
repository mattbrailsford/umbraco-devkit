#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Stack

- Umbraco CMS: 17
- Database: SQL Server + SQLite
- Demo site: `demo/TagCloud.Demo`, references `Umbraco.Community.WorktreeDevPort`. No e2e suite.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
MD
D=docs/plans/tag-dashboard
mkdir -p $D/mockups $D/screenshots src/Client demo/TagCloud.Demo
cat > demo/TagCloud.Demo/TagCloud.Demo.csproj <<'MD'
<Project Sdk="Microsoft.NET.Sdk.Web">
  <ItemGroup><PackageReference Include="Umbraco.Community.WorktreeDevPort" Version="1.0.0" /></ItemGroup>
</Project>
MD
# A tiny solid PNG, so a real image sits where the mockup and before shot belong.
python3 - "$D/mockups/tag-dashboard.png" "$D/screenshots/tag-dashboard-before.png" <<'PY'
import sys, zlib, struct
def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d))
w, h = 64, 40
raw = b''.join(b'\x00' + b'\xee\xee\xf4' * w for _ in range(h))
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) \
    + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')
for p in sys.argv[1:]: open(p, 'wb').write(png)
PY
cat > src/Client/tag-dashboard.element.ts <<'MD'
import { html, customElement } from '@umbraco-cms/backoffice/external/lit';
import { UmbLitElement } from '@umbraco-cms/backoffice/lit-element';

@customElement('tag-cloud-dashboard')
export class TagCloudDashboardElement extends UmbLitElement {
  override render() {
    return html`<uui-table></uui-table>`;
  }
}
MD
cat > $D/README.md <<'MD'
# Tag dashboard

1. [x] [BRIEF.md](./BRIEF.md) — editors see which tags are used most
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — a dashboard in the Content section
3. [x] [SPEC.md](./SPEC.md) — tag, count, sorted by count; mockup in mockups/
4. [x] [STORIES.md](./STORIES.md) — one story
5. [x] [PLAN.md](./PLAN.md) — three tasks
MD
cat > $D/BRIEF.md <<'MD'
# Tag dashboard: brief

Editors can't see which tags are used most without opening every page.
MD
cat > $D/ARCHITECTURE.md <<'MD'
# Tag dashboard: architecture

- A dashboard in the Content section, `tag-cloud-dashboard`, reads counts from the existing
  `TagCloudService` through a Management API endpoint added in T1.
MD
cat > $D/SPEC.md <<'MD'
# Tag dashboard: spec

- Content › Tag cloud shows every tag with its count, highest first.
- Layout as in `mockups/tag-dashboard.png`.
MD
cat > $D/STORIES.md <<'MD'
# Tag dashboard: stories

1. As an editor, I can see which tags are used most.
MD
cat > $D/PLAN.md <<'MD'
# Tag dashboard: plan

- [x] **T1** - story: 1. Management API endpoint returning tag counts.
  depends-on: none

- [ ] **T2** - story: 1. The Tag cloud dashboard in the Content section, listing each tag
  with its count, highest first, as in the mockup. Changes the existing placeholder dashboard.
  Acceptance: Content › Tag cloud shows the counts.
  depends-on: T1

- [ ] **T3** - story: 1. Sort and filter controls.
  depends-on: T2
MD
cat > $D/DECISION-LOG.md <<'MD'
# Tag dashboard: decision log
MD
cat > $D/BUILD-LOG.md <<'MD'
# Tag dashboard: build log

Branch `tag-dashboard`, worktree `../tag-dashboard`.

- T1: endpoint added. Reviewer PASS on round 1. `5d0b7e1`.
- T2: before shot saved, `screenshots/tag-dashboard-before.png` (Content › Tag cloud).
MD

# This case: T2 is built, but the running demo site doesn't show it, because the package's
# manifest fails to load. The site log says why.
mkdir -p logs demo/TagCloud.Demo/wwwroot/App_Plugins/TagCloud
cat > demo/TagCloud.Demo/wwwroot/App_Plugins/TagCloud/umbraco-package.json <<'JSON'
{
  "name": "TagCloud",
  "extensions": [
    { "type": "dashboard", "alias": "TagCloud.Dashboard", "element": "/App_Plugins/TagCloud/tag-dashboard.js",
      "meta": { "label": "Tag cloud", "pathname": "tag-cloud" }, }
  ]
}
JSON
cat > logs/demo-site.log <<'LOG'
[09:12:01 INF] Now listening on: https://localhost:44317
[09:12:01 INF] Application started. Press Ctrl+C to shut down.
[09:12:04 INF] Acquiring MainDom.
[09:12:05 INF] Booted Umbraco in 4120 ms.
[09:41:17 INF] Application is shutting down...
[09:41:22 INF] Now listening on: https://localhost:44317
[09:41:26 INF] Booted Umbraco in 3984 ms.
[09:41:31 ERR] Failed to read package manifest App_Plugins/TagCloud/umbraco-package.json
System.Text.Json.JsonException: The JSON object contains a trailing comma at the end which is not supported in this mode. Path: $.extensions[0].meta | LineNumber: 4 | BytePositionInLine: 63.
[09:41:31 WRN] Package TagCloud has no extensions registered.
LOG
cat > $D/BUILD-LOG.md <<'MD'
# Tag dashboard: build log

Demo site: https://localhost:44317, started with `dotnet run --project demo/TagCloud.Demo`,
log `logs/demo-site.log`.

Branch `tag-dashboard`, worktree `../tag-dashboard`.

- T1: endpoint added. Reviewer PASS on round 1. `5d0b7e1`.
- T2: before shot saved, `screenshots/tag-dashboard-before.png` (Content › Tag cloud).
  Builder done, reviewer PASS on round 1. Site restarted at 09:41 to pick it up.
MD
