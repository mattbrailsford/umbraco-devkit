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
  {"number": 101, "title": "Cloud ignores the MaxTags setting", "body": "Setting MaxTags to 10 on the Tag Cloud data type still shows every tag. Umbraco 17.1, package 4.2.0.", "labels": [], "updatedAt": "2026-10-15"},
  {"number": 102, "title": "Support tag groups in the Delivery API", "body": "We use tag groups for regions. Could the Delivery API return tags for one group only?", "labels": [], "updatedAt": "2026-10-15"},
  {"number": 94, "title": "Show tag counts on hover", "body": "It would help editors to see how often each tag is used when hovering it.", "labels": ["state/needs-decision"], "updatedAt": "2026-10-10"},
  {"number": 88, "title": "Cloud empty after upgrading to 17.1", "body": "After upgrading the site from 17.0 to 17.1 the cloud renders empty on every page until we restart.", "labels": ["state/needs-investigation"], "updatedAt": "2026-10-09"},
  {"number": 90, "title": "Wrong weights with variant content", "body": "On a site with English and Danish, tag weights look doubled on the Danish pages.", "labels": ["state/needs-investigation"], "updatedAt": "2026-10-11"},
  {"number": 91, "title": "Slow dashboard with 5,000 tags", "body": "The Tag Cloud dashboard takes about 20 seconds to load on a site with 5,000 tags.", "labels": ["state/needs-investigation"], "updatedAt": "2026-10-12"},
  {"number": 86, "title": "Crash on startup on Azure", "body": "The site crashes on startup on Azure App Service after installing the package. Works locally.", "labels": ["state/needs-info"], "updatedAt": "__RECENT__", "note": "needs-info added __RECENT__; no reply from the reporter since"},
  {"number": 80, "title": "Tags with spaces break the link", "body": "A tag like 'open source' links to /tags/open and the page 404s.", "labels": ["state/ready"], "updatedAt": "2026-10-08"},
  {"number": 82, "title": "Typo in the settings label", "body": "The settings label says 'Maxium tags' instead of 'Maximum tags'.", "labels": ["state/ready"], "updatedAt": "2026-10-08"},
  {"number": 79, "title": "Dark mode colours", "body": "Cloud colours are unreadable in the backoffice dark theme.", "labels": ["state/in-progress"], "updatedAt": "2026-10-13"}
]
EOF
# Keep #86 inside the 30-day needs-info timeout whenever the case runs.
RECENT=$(date -u -d '5 days ago' +%F 2>/dev/null || date -u -v-5d +%F)
sed -i.bak "s/__RECENT__/$RECENT/g" ISSUES.json && rm ISSUES.json.bak
