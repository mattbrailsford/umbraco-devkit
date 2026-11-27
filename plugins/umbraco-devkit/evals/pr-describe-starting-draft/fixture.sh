#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`.
MD
D=docs/plans/tag-dashboard
mkdir -p $D
cat > $D/README.md <<'MD'
# Tag dashboard

1. [x] [BRIEF.md](./BRIEF.md) - editors see which tags are used most
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) - a dashboard in the Content section
3. [x] [SPEC.md](./SPEC.md) - tag, count, sorted by count
4. [x] [PLAN.md](./PLAN.md) - two tasks
MD
cat > $D/BRIEF.md <<'MD'
# Tag dashboard: brief

Editors can't see which tags are used most without opening every page, so tag lists drift
and duplicates pile up. A dashboard listing each tag with how often it's used fixes that.
Out of scope: editing or merging tags.
MD
cat > $D/ARCHITECTURE.md <<'MD'
# Tag dashboard: architecture

- A dashboard in the Content section, `tag-cloud-dashboard`, reads counts from a new
  Management API endpoint, `GET tagcloud/tags/counts`.
MD
cat > $D/SPEC.md <<'MD'
# Tag dashboard: spec

- Content › Tag cloud lists every tag in use with its count, highest first.
MD
cat > $D/PLAN.md <<'MD'
# Tag dashboard: plan

- [ ] **T1** - Management API endpoint returning tag counts, highest first.
- [ ] **T2** - The Tag cloud dashboard in the Content section.
MD
cat > $D/DECISION-LOG.md <<'MD'
# Tag dashboard: decision log
MD
cat > TOOL-OUTPUT.txt <<'TXT'
$ git rev-parse --abbrev-ref HEAD
tag-dashboard

$ git config --get branch.tag-dashboard.merge
refs/heads/tag-dashboard

$ git log --oneline -2
a41c9e2 docs: add plan folder for tag-dashboard
77d0f13 chore: bump Umbraco to 17.0.2

$ git rev-parse HEAD
a41c9e2f6b0d3c51e8a9d7742c0f1b6e93a5d210

$ git status --short
(clean)

$ git ls-remote --heads origin tag-dashboard
a41c9e2f6b0d3c51e8a9d7742c0f1b6e93a5d210	refs/heads/tag-dashboard

$ gh repo view --json nameWithOwner,defaultBranchRef
{"nameWithOwner":"acme/tagcloud","defaultBranchRef":{"name":"main"}}

$ gh pr view --json url,number,title,state,baseRefName,headRefName
no pull requests found for branch "tag-dashboard"

$ git diff main...HEAD --stat
 docs/plans/tag-dashboard/ (6 files, all new)
TXT
