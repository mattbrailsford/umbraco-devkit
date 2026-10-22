#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.TagCloud

An Umbraco package (C# plus a Lit backoffice client).

## Issue tracker

- Type: GitHub Issues
- Location: this repo, `jodean/Umbraco.Community.TagCloud`
- Access: `gh`
- State labels: the defaults
- Proposal answers: start a comment with 🤖
- Auto-apply: needs-investigation
EOF
cat > PROPOSALS.json <<'EOF'
[
 {
  "issue": 201,
  "created": "2026-08-13",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto -->",
  "summary": "Applied automatically: needs investigation · not reviewed yet"
 },
 {
  "issue": 202,
  "created": "2026-09-14",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto -->",
  "summary": "Applied automatically: needs investigation · not reviewed yet"
 },
 {
  "issue": 203,
  "created": "2026-09-15",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto -->",
  "summary": "Applied automatically: needs investigation · not reviewed yet"
 },
 {
  "issue": 204,
  "created": "2026-08-16",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto -->",
  "summary": "Applied automatically: needs investigation · not reviewed yet"
 },
 {
  "issue": 205,
  "created": "2026-09-17",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto -->",
  "summary": "Applied automatically: needs investigation · not reviewed yet"
 },
 {
  "issue": 206,
  "created": "2026-09-18",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto -->",
  "summary": "Applied automatically: needs investigation · not reviewed yet"
 },
 {
  "issue": 207,
  "created": "2026-08-19",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto -->",
  "summary": "Applied automatically: needs investigation · not reviewed yet"
 },
 {
  "issue": 208,
  "created": "2026-09-20",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto -->",
  "summary": "Applied automatically: needs investigation · not reviewed yet"
 },
 {
  "issue": 209,
  "created": "2026-09-21",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto -->",
  "summary": "Applied automatically: needs investigation · not reviewed yet"
 },
 {
  "issue": 210,
  "created": "2026-08-22",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto -->",
  "summary": "Applied automatically: needs investigation · not reviewed yet"
 },
 {
  "issue": 211,
  "created": "2026-09-23",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto -->",
  "summary": "Applied automatically: needs investigation · not reviewed yet"
 },
 {
  "issue": 212,
  "created": "2026-09-24",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto -->",
  "summary": "Applied automatically: needs investigation · not reviewed yet"
 },
 {
  "issue": 213,
  "created": "2026-08-25",
  "marker": "<!-- issue-triage:proposal first=needs-investigation auto changed -->",
  "summary": "Approved: needs info · by @jodean"
 },
 {
  "issue": 214,
  "created": "2026-09-26",
  "marker": "<!-- issue-triage:proposal first=needs-decision -->",
  "summary": "Approved: needs decision · by @jodean"
 },
 {
  "issue": 215,
  "created": "2026-09-27",
  "marker": "<!-- issue-triage:proposal first=needs-decision -->",
  "summary": "Approved: needs decision · by @jodean"
 },
 {
  "issue": 216,
  "created": "2026-08-01",
  "marker": "<!-- issue-triage:proposal first=needs-decision -->",
  "summary": "Approved: needs decision · by @jodean"
 },
 {
  "issue": 217,
  "created": "2026-09-02",
  "marker": "<!-- issue-triage:proposal first=needs-decision -->",
  "summary": "Approved: needs decision · by @jodean"
 },
 {
  "issue": 218,
  "created": "2026-09-03",
  "marker": "<!-- issue-triage:proposal first=needs-decision -->",
  "summary": "Approved: needs decision · by @jodean"
 },
 {
  "issue": 219,
  "created": "2026-08-04",
  "marker": "<!-- issue-triage:proposal first=needs-decision -->",
  "summary": "Approved: needs decision · by @jodean"
 },
 {
  "issue": 220,
  "created": "2026-09-05",
  "marker": "<!-- issue-triage:proposal first=needs-decision -->",
  "summary": "Approved: needs decision · by @jodean"
 },
 {
  "issue": 221,
  "created": "2026-09-06",
  "marker": "<!-- issue-triage:proposal first=needs-decision -->",
  "summary": "Approved: needs decision · by @jodean"
 },
 {
  "issue": 222,
  "created": "2026-08-07",
  "marker": "<!-- issue-triage:proposal first=needs-decision -->",
  "summary": "Approved: needs decision · by @jodean"
 },
 {
  "issue": 223,
  "created": "2026-09-08",
  "marker": "<!-- issue-triage:proposal first=needs-decision -->",
  "summary": "Approved: needs decision · by @jodean"
 },
 {
  "issue": 224,
  "created": "2026-09-09",
  "marker": "<!-- issue-triage:proposal first=needs-info -->",
  "summary": "Approved: needs info · by @jodean"
 },
 {
  "issue": 225,
  "created": "2026-08-10",
  "marker": "<!-- issue-triage:proposal first=needs-info -->",
  "summary": "Approved: needs info · by @jodean"
 },
 {
  "issue": 226,
  "created": "2026-09-11",
  "marker": "<!-- issue-triage:proposal first=needs-info -->",
  "summary": "Approved: needs info · by @jodean"
 },
 {
  "issue": 227,
  "created": "2026-09-12",
  "marker": "<!-- issue-triage:proposal first=needs-info -->",
  "summary": "Approved: needs info · by @jodean"
 },
 {
  "issue": 228,
  "created": "2026-08-13",
  "marker": "<!-- issue-triage:proposal first=needs-info -->",
  "summary": "Approved: needs info · by @jodean"
 },
 {
  "issue": 229,
  "created": "2026-09-14",
  "marker": "<!-- issue-triage:proposal first=needs-info -->",
  "summary": "Approved: needs info · by @jodean"
 },
 {
  "issue": 230,
  "created": "2026-09-15",
  "marker": "<!-- issue-triage:proposal first=needs-info -->",
  "summary": "Proposed: needs info · automated first look, not decided"
 },
 {
  "issue": 231,
  "created": "2026-08-16",
  "marker": "<!-- issue-triage:proposal first=close -->",
  "summary": "Approved: close · by @jodean"
 },
 {
  "issue": 232,
  "created": "2026-09-17",
  "marker": "<!-- issue-triage:proposal first=close -->",
  "summary": "Approved: close · by @jodean"
 },
 {
  "issue": 233,
  "created": "2026-09-18",
  "marker": "<!-- issue-triage:proposal first=close -->",
  "summary": "Approved: close · by @jodean"
 },
 {
  "issue": 234,
  "created": "2026-08-19",
  "marker": "<!-- issue-triage:proposal first=close -->",
  "summary": "Approved: close · by @jodean"
 },
 {
  "issue": 235,
  "created": "2026-09-20",
  "marker": "<!-- issue-triage:proposal first=close changed -->",
  "summary": "Approved: needs info · by @jodean"
 },
 {
  "issue": 236,
  "created": "2026-09-21",
  "marker": "<!-- issue-triage:proposal first=close changed -->",
  "summary": "Approved: needs info · by @jodean"
 }
]
EOF
