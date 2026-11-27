#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'MD'
# Umbraco.Community.TagCloud

An Umbraco 17 package (a Lit backoffice client plus C#). Open source; trunk branch: `main`.

## Issue tracker

- Type: GitHub Issues
- Location: this repo, `jodean/Umbraco.Community.TagCloud`
- Access: `gh`
MD
mkdir -p src/client/lang
cat > src/client/lang/en.ts <<'TS'
export default {
  tagCloud: {
    maxTagsLabel: 'Maxium tags',
    maxTagsDescription: 'The most tags the cloud shows. Leave empty to show every tag.',
  },
};
TS
git add -A && git commit -q -m "feat: settings labels"
git checkout -q -b fix-label-spelling
sed -i.bak "s/Maxium tags/Maximum tags/" src/client/lang/en.ts && rm src/client/lang/en.ts.bak
git add -A && git diff --cached HEAD > PR.diff
git commit -q -m "fix: spelling of the max tags label"
SHA=$(git rev-parse HEAD)
cat > PR.json <<JSON
{
  "number": 156,
  "title": "Fix spelling of the max tags label",
  "body": "The settings label said 'Maxium tags'. Fixed the spelling.",
  "author": {"login": "sofie-h"},
  "authorAssociation": "CONTRIBUTOR",
  "baseRefName": "main",
  "headRefName": "fix-label-spelling",
  "headRefOid": "$SHA",
  "files": [{"path": "src/client/lang/en.ts", "additions": 1, "deletions": 1}],
  "closingIssuesReferences": [],
  "reviews": [],
  "mergeable": "MERGEABLE",
  "checks": [{"name": "build", "state": "SUCCESS"}, {"name": "test", "state": "SUCCESS"}]
}
JSON
cat > ISSUES.json <<'JSON'
[
  {"number": 80, "title": "Tags with spaces break the link", "body": "A tag like 'open source' links to /tags/open and the page 404s.", "labels": ["bug", "state/ready"]},
  {"number": 82, "title": "Typo in the settings label", "body": "The settings label says 'Maxium tags' instead of 'Maximum tags'.", "labels": ["bug", "state/ready"]},
  {"number": 91, "title": "Slow dashboard with 5,000 tags", "body": "The dashboard takes about 20 seconds to load with 5,000 tags.", "labels": ["bug", "state/needs-investigation"]}
]
JSON
cat > REPO.json <<'JSON'
{
  "defaultBranch": "main",
  "mergeCommitAllowed": true,
  "squashMergeAllowed": true,
  "rebaseMergeAllowed": false,
  "recentMerges": [
    {"number": 150, "method": "squash"},
    {"number": 147, "method": "squash"},
    {"number": 141, "method": "squash"}
  ]
}
JSON
