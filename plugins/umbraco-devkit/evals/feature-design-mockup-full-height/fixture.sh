#!/usr/bin/env bash
set -euo pipefail
# The eval sandbox can't start full Chrome or read the user's home, so clone Playwright's
# headless shell into the workspace (copy-on-write on APFS, so it's instant).
# Scaffolds run with a sandbox $HOME, so find the real one from the user database.
home=$(eval echo "~$(id -un)")
shell=$(ls -d "$home"/Library/Caches/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-* 2>/dev/null | tail -1)
[ -n "$shell" ] || { echo "Needs Playwright's headless shell: npx playwright install chromium-headless-shell" >&2; exit 1; }
mkdir -p tools
cp -cR "$shell" tools/chrome-headless-shell 2>/dev/null || cp -R "$shell" tools/chrome-headless-shell
cat > CLAUDE.md <<'MD'
# MyCompany.Usage

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
MD
mkdir -p docs/plans/usage-dashboard/mockups
cat > docs/plans/usage-dashboard/README.md <<'MD'
# Usage dashboard

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — show editors this month's API usage on one dashboard
2. [ ] [ARCHITECTURE.md](./ARCHITECTURE.md) — <pending>
3. [ ] [SPEC.md](./SPEC.md) — <pending>
4. [ ] [STORIES.md](./STORIES.md) — <pending>
5. [ ] [PLAN.md](./PLAN.md) — <pending>
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
MD
cat > docs/plans/usage-dashboard/BRIEF.md <<'MD'
# Brief

## Problem

Editors can't see how much of their monthly API allowance they've used until the bill
arrives. They want one dashboard with the month's totals, a daily chart, and the biggest
callers.

## Who

Editors and site admins who own the API budget.

## Success

An editor opens the Usage dashboard and sees this month's requests, tokens and cost, how
they trend by day, and which callers use the most.

## Out of scope

Alerts and spending limits.
MD
cat > docs/plans/usage-dashboard/DECISION-LOG.md <<'MD'
# Decision log
MD
cat > docs/plans/usage-dashboard/mockups/usage.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Usage dashboard</title>
<style>
  body { margin: 0; font-family: Lato, Helvetica, Arial, sans-serif; background: #f3f3f5; color: #1b264f; }
  header { height: 60px; background: #1b264f; color: #fff; display: flex; align-items: center; padding: 0 20px; gap: 24px; }
  main { padding: 32px 48px; }
  h2 { font-size: 15px; margin: 32px 0 12px; }
  .grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; }
  .tile { background: #fff; border: 1px solid #e4e4e8; border-radius: 3px; padding: 20px; min-height: 120px; }
  .tile b { display: block; font-size: 28px; margin-top: 8px; }
  .chart { background: #fff; border: 1px solid #e4e4e8; border-radius: 3px; height: 360px; }
  table { width: 100%; background: #fff; border-collapse: collapse; }
  td, th { text-align: left; padding: 12px 16px; border-bottom: 1px solid #e4e4e8; }
</style>
</head>
<body>
<header><strong>Umbraco</strong><span>Content</span><span>Settings</span><span>Usage</span></header>
<main>
  <h2>This month</h2>
  <div class="grid">
    <div class="tile">REQUESTS<b>1.28M</b></div>
    <div class="tile">INPUT TOKENS<b>134.8K</b></div>
    <div class="tile">OUTPUT TOKENS<b>21.4K</b></div>
    <div class="tile">COST<b>€12.40</b></div>
  </div>
  <h2>Requests by day</h2>
  <div class="chart">
    <svg width="100%" height="100%" viewBox="0 0 1000 360" preserveAspectRatio="none">
      <polyline fill="none" stroke="#3544b1" stroke-width="3"
        points="0,300 100,260 200,280 300,200 400,220 500,150 600,170 700,120 800,140 900,90 1000,110"/>
    </svg>
  </div>
  <h2>Top callers</h2>
  <table>
    <tr><th>Caller</th><th>Requests</th><th>Cost</th></tr>
    <tr><td>Search indexer</td><td>612,400</td><td>€5.10</td></tr>
    <tr><td>Content assistant</td><td>402,100</td><td>€4.20</td></tr>
    <tr><td>Translation job (nightly, all cultures, long caller name that wraps)</td><td>198,300</td><td>€2.30</td></tr>
    <tr><td>Image alt-text</td><td>67,200</td><td>€0.80</td></tr>
  </table>
  <h2>Other states</h2>
  <div class="grid">
    <div class="tile">EMPTY<b>—</b>No usage yet this month</div>
    <div class="tile">ERROR<b>—</b>Couldn't load usage. Try again.</div>
    <div class="tile">LOADING<b>…</b></div>
    <div class="tile">NO ACCESS<b>—</b>Ask an admin for access</div>
  </div>
</main>
<script>document.documentElement.dataset.mockupReady = "";</script>
</body>
</html>
HTML
