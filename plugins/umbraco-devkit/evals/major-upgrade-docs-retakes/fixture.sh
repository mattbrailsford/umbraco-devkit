#!/usr/bin/env bash
set -euo pipefail
mkdir -p src/Umbraco.Community.StockLevels docs/images docs/upgrades/v18-screens
cat > CLAUDE.md <<'MD'
# Umbraco.Community.StockLevels

An Umbraco package (C# plus a Lit backoffice client). The package version follows the CMS
major. Trunk for the upgrade: `v18/dev`.

## Build & test

- Demo site: `dotnet run --project demo/StockLevels.Demo` (port from `git wdp-port`)

## Docs

User docs live in `docs/` in this repo, with their images in `docs/images/`.
MD
# Tiny solid PNGs where the docs images and the comparison screenshots belong.
python3 - docs/images/stock-dashboard.png docs/images/stock-editor.png \
  docs/upgrades/v18-screens/stock-dashboard-v17.png docs/upgrades/v18-screens/stock-dashboard-v18.png <<'PY'
import sys, zlib, struct
def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d))
w, h = 64, 40
raw = b''.join(b'\x00' + b'\xee\xee\xf4' * w for _ in range(h))
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) \
    + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')
for p in sys.argv[1:]: open(p, 'wb').write(png)
PY
cat > docs/dashboard.md <<'MD'
# The stock dashboard

Open **Content › Stock** to see every product's stock level.

![The stock dashboard](images/stock-dashboard.png)
MD
cat > docs/editor.md <<'MD'
# Editing a stock level

Open any product and use the **Stock level** field.

![The stock level field](images/stock-editor.png)
MD
cat > docs/upgrades/v18.md <<'MD'
# Upgrade to Umbraco 18

From `17.6.1` to `18.0.0` (tag `release-18.0.0`).
Branch `v18/feature/cms-18`, cut from `v18/dev`.

**Targets CMS release:** `release-18.0.0`.

## Inventory

- **`@umbraco-cms/backoffice` 17.6.1 → 18.0.0** (18.0.0)\
  Source: `release-18.0.0:src/Umbraco.Web.UI.Client/package.json`\
  Hits: `src/Umbraco.Community.StockLevels/Client/package.json`

## Screen comparison

Every screen the package adds, compared before and after the upgrade smoke (screenshots in
`v18-screens/`).

- **Stock dashboard**. Content › Stock.\
  Difference: CMS change: new UUI table styling and header.
- **Stock level property editor**. Content › any product › Stock level.\
  Difference: none.

## Docs

Docs: `docs/` in this repo, searched.

- **docs/installation.md**. Says "Umbraco 17".\
  Fix: Umbraco 18. Done in the docs task.

Screenshots to retake (Finish step 3):

- **docs/images/stock-dashboard.png**, on docs/dashboard.md. Content › Stock.\
  Why: CMS change: new UUI table styling and header.

## Blockers

None.

## Tasks

- [x] Bump target framework and Umbraco packages; fix compile errors
- [x] Bump `@umbraco-cms/backoffice`; fix the client
- [x] Update compatibility markers
- [x] Update the docs pages and screenshots in "Docs", when they're in this repo

## Decisions

## Breaking changes for consumers

None.

## Log

Demo site: https://localhost:44391, started with `dotnet run --project demo/StockLevels.Demo`,
log `../cms-18-site.log`. Running on 18 with the upgraded package.

- a1b2c3d: bump to 18.0.0, build and tests green.
- d4e5f6a: compatibility markers.
- Finish: full tests green on SQLite and SQL Server; upgrade smoke from 17 PASS.
- Finish: screen comparison done by smoke-testers; results in the table above.
MD
