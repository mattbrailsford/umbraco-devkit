#!/usr/bin/env bash
set -euo pipefail
git init -q -b support/17.x
git config user.email dev@example.com
git config user.name Dev
mkdir -p src/Umbraco.Community.StockLevels/Client/src docs/upgrades
cat > CLAUDE.md <<'MD'
# Umbraco.Community.StockLevels

An Umbraco package (C# plus a Lit backoffice client) with a branch per CMS major. The package
version follows the CMS major.

## Version lines

- `v18/dev`: Umbraco 18, being built. Active.
- `support/17.x`: Umbraco 17. Active: fixes and small features, released as patches.

Fixes for 17.x go on a `hotfix/<slug>` branch off `support/17.x`.
MD
cat > src/Umbraco.Community.StockLevels/Client/src/stock-dashboard.element.ts <<'TS'
import { html, customElement, state } from '@umbraco-cms/backoffice/external/lit';
import { UmbLitElement } from '@umbraco-cms/backoffice/lit-element';

@customElement('stock-dashboard')
export class StockDashboardElement extends UmbLitElement {
  @state() private _lowOnly = false;

  async #save(key: string, level: number) {
    await this.#repository.saveLevel(key, level);
    this._lowOnly = false;
    await this.#load();
  }

  render() {
    return html`<uui-toggle label="Low stock only" .checked=${this._lowOnly}></uui-toggle>`;
  }
}
TS
git add -A && git commit -qm "feat: stock dashboard"
git switch -qc v18/dev
git commit -qam "chore: bump Umbraco to 18.0.0" --allow-empty
python3 - src/Umbraco.Community.StockLevels/Client/src/stock-dashboard.element.ts <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace("    this._lowOnly = false;\n", "")
open(p, "w").write(s)
PY
git commit -qam "fix: keep the low-stock filter after saving a level" \
  -m "Saving a level reset the filter to show every product."
fix=$(git rev-parse --short HEAD)
git commit -qm "chore: update compatibility markers for v18" --allow-empty
cat > docs/upgrades/v18.md <<MD
# Upgrade to Umbraco 18

From \`17.6.1\` to \`18.0.0\` (tag \`release-18.0.0\`).
Branch \`v18/dev\`, cut from \`support/17.x\`.

**Targets CMS release:** \`release-18.0.0\`.

## Inventory

- **\`@umbraco-cms/backoffice\` 17.6.1 → 18.0.0** (18.0.0)\\
  Source: \`release-18.0.0:src/Umbraco.Web.UI.Client/package.json\`\\
  Hits: \`src/Umbraco.Community.StockLevels/Client/package.json\`

## Blockers

None.

## Tasks

Each task ends in a green build.

- [x] Bump target framework and Umbraco packages; fix compile errors
- [x] Bump \`@umbraco-cms/backoffice\`; fix the client
- [x] Update compatibility markers

## Decisions

## Breaking changes for consumers

None.

## Follow-ups

## Log

- a1b2c3d: bump to 18.0.0, build and tests green.
- $fix: smoke found the low-stock filter resetting after a save. Fixed.
- d4e5f6a: compatibility markers.
MD
git add -A && git commit -qm "docs: update upgrade plan for v18"
