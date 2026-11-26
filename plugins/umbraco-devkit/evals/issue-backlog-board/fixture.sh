#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.TagCloud

An Umbraco package (C# plus a Lit backoffice client).

## Version lines

| Line | Integration branch | Release branch | Phase |
|---|---|---|---|
| Umbraco 17 | `v17/dev` | `v17/main` | Active: features and fixes |
| Umbraco 13 | `v13/dev` | `v13/main` | Security fixes only, until 2026-12-14 |

## Issue tracker

- Type: GitHub Issues
- Location: this repo, `jodean/Umbraco.Community.TagCloud`
- Access: `gh`
- State labels: the defaults
EOF
cat > ISSUES.json <<'EOF'
[
  {"number": 101, "title": "Cloud ignores the MaxTags setting", "labels": [], "updatedAt": "2026-10-15"},
  {"number": 102, "title": "Support tag groups in the Delivery API", "labels": [], "updatedAt": "2026-10-15"},
  {"number": 94, "title": "Show tag counts on hover", "labels": ["state/needs-decision"], "updatedAt": "2026-10-10"},
  {"number": 88, "title": "Cloud empty after upgrading to 17.1", "labels": ["state/needs-investigation"], "updatedAt": "2026-10-09"},
  {"number": 90, "title": "Wrong weights with variant content", "labels": ["state/needs-investigation"], "updatedAt": "2026-10-11"},
  {"number": 91, "title": "Slow dashboard with 5,000 tags", "labels": ["state/needs-investigation"], "updatedAt": "2026-10-12"},
  {"number": 86, "title": "Crash on startup on Azure", "labels": ["state/needs-info"], "updatedAt": "__RECENT__", "note": "needs-info added __RECENT__; no reply from the reporter since"},
  {"number": 80, "title": "Tags with spaces break the link", "labels": ["state/ready"], "updatedAt": "2026-10-08"},
  {"number": 82, "title": "Typo in the settings label", "labels": ["state/ready"], "updatedAt": "2026-10-08"},
  {"number": 79, "title": "Dark mode colours", "labels": ["state/in-progress"], "updatedAt": "2026-10-13"}
]
EOF
# Keep #86 inside the 30-day needs-info timeout whenever the case runs.
RECENT=$(date -u -d '5 days ago' +%F 2>/dev/null || date -u -v-5d +%F)
sed -i.bak "s/__RECENT__/$RECENT/g" ISSUES.json && rm ISSUES.json.bak
