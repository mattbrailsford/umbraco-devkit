#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# MyCompany.Newsletter

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
MD
mkdir -p docs/plans/shared-issues-tree/mockups
cat > docs/plans/shared-issues-tree/README.md <<'MD'
# Shared issues in the tree

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — show which issues are shared, right in the Newsletters tree
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — a marker on shared issues in the existing tree
3. [x] [SPEC.md](./SPEC.md) — the tree with shared issues marked; its mockup still pending
4. [ ] [STORIES.md](./STORIES.md) — <pending>
5. [ ] [PLAN.md](./PLAN.md) — <pending>
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
MD
cat > docs/plans/shared-issues-tree/BRIEF.md <<'MD'
# Brief

## Problem

Editors can share a draft issue with colleagues, but nothing in the Newsletters tree shows
which issues are shared. Reviewers can't spot what's waiting for them, and authors forget a
draft is still open to others.

## Who

Editors who write newsletter issues, and the colleagues who review them.

## Success

An editor looking at the Newsletters tree can tell at a glance which issues are shared, and
with how many people, without opening any of them.

## Out of scope

Changing who an issue is shared with (the existing Share action does that).
MD
cat > docs/plans/shared-issues-tree/ARCHITECTURE.md <<'MD'
# Architecture

## Extension points

The existing Newsletters tree (section "Newsletters", tree "Issues"). No new section, screen
or tree.

## Key decisions

- **Marked in the tree, not a separate "Shared" folder.** An issue stays where it lives; a
  second folder would show it twice.
MD
cat > docs/plans/shared-issues-tree/SPEC.md <<'MD'
# Spec

## Frontend components

### Newsletters tree with shared issues

<!-- Mockup still pending (`mockups/tree-shared.html`); this phase isn't finished until it
     exists. -->

The Newsletters section with its Issues tree open. Issues shared with at least one other
person are marked as shared; hovering the marker says "Shared with 2 people". Show five
issues: two shared, one of those the open (active) one. The main area shows the active
issue's editor as it already is today; this feature doesn't change it.
MD
cat > docs/plans/shared-issues-tree/DECISION-LOG.md <<'MD'
# Decision log

- 03-11-2026 — Marked in the tree, not a separate "Shared" folder (see ARCHITECTURE.md).
MD
