#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# Umbraco.Community.TagCloud

An Umbraco package (C# plus a Lit backoffice client). Open source; trunk branch: `main`.

## Issue tracker

- Type: GitHub Issues
- Location: this repo, `jodean/Umbraco.Community.TagCloud`
- Access: `gh`
- State labels: the defaults
MD
cat > ISSUES.json <<'JSON'
[
  {"number": 88, "title": "Cloud empty after upgrading to 17.1", "body": "After upgrading from 17.0 to 17.1 the cloud renders empty until we restart.", "labels": ["bug", "state/needs-investigation"], "updatedAt": "2026-10-09"},
  {"number": 91, "title": "Slow dashboard with 5,000 tags", "body": "The dashboard takes about 20 seconds to load with 5,000 tags.", "labels": ["bug", "state/needs-investigation"], "updatedAt": "2026-10-12"},
  {"number": 80, "title": "Tags with spaces break the link", "body": "A tag like 'open source' links to /tags/open and the page 404s.", "labels": ["bug", "state/ready"], "updatedAt": "2026-10-08"},
  {"number": 79, "title": "Dark mode colours", "body": "Cloud colours are unreadable in the dark theme.", "labels": ["bug", "state/in-progress"], "updatedAt": "2026-10-13"}
]
JSON
cat > PULLS.json <<'JSON'
[
  {"number": 121, "title": "Bump vite from 6.3.1 to 6.3.6", "user": {"login": "dependabot[bot]", "type": "Bot"}, "author_association": "NONE", "draft": false, "created_at": "2026-10-14",
   "commits": [{"date": "2026-10-14"}], "reviews": []},
  {"number": 120, "title": "Encode tag names in cloud links", "body": "Spaces in tag names broke the links. This encodes them.", "user": {"login": "sofie-h", "type": "User"}, "author_association": "CONTRIBUTOR", "draft": false, "created_at": "2026-10-13",
   "commits": [{"date": "2026-10-13"}], "reviews": []},
  {"number": 119, "title": "Refactor the tag service", "user": {"login": "jodean", "type": "User"}, "author_association": "OWNER", "draft": false, "created_at": "2026-10-12",
   "commits": [{"date": "2026-10-12"}], "reviews": []},
  {"number": 118, "title": "Add Danish translations", "user": {"login": "lars-k", "type": "User"}, "author_association": "FIRST_TIME_CONTRIBUTOR", "draft": false, "created_at": "2026-10-06",
   "commits": [{"date": "2026-10-11"}], "reviews": [{"user": "jodean", "author_association": "OWNER", "state": "APPROVED", "submitted_at": "2026-10-12"}]},
  {"number": 117, "title": "Sort tags alphabetically option", "user": {"login": "mei-w", "type": "User"}, "author_association": "CONTRIBUTOR", "draft": false, "created_at": "2026-10-01",
   "commits": [{"date": "2026-10-01"}, {"date": "2026-10-13"}], "reviews": [{"user": "jodean", "author_association": "OWNER", "state": "CHANGES_REQUESTED", "submitted_at": "2026-10-05"}]},
  {"number": 115, "title": "Cache tag counts per culture", "user": {"login": "tomas-r", "type": "User"}, "author_association": "CONTRIBUTOR", "draft": false, "created_at": "2026-09-28",
   "commits": [{"date": "2026-10-09"}], "reviews": [{"user": "jodean", "author_association": "OWNER", "state": "CHANGES_REQUESTED", "submitted_at": "2026-10-10"}]},
  {"number": 114, "title": "WIP: tag groups in the Delivery API", "user": {"login": "anna-p", "type": "User"}, "author_association": "CONTRIBUTOR", "draft": true, "created_at": "2026-09-20",
   "commits": [{"date": "2026-09-20"}], "reviews": []}
]
JSON
