#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# MyCompany.Newsletter

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
MD
mkdir -p docs/plans/share-issues/mockups
cat > docs/plans/share-issues/README.md <<'MD'
# Share issues

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — let an editor share a draft newsletter issue with colleagues
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — a "Share" entity action opening a sidebar modal
3. [x] [SPEC.md](./SPEC.md) — the share modal; its mockup still pending
4. [ ] [STORIES.md](./STORIES.md) — <pending>
5. [ ] [PLAN.md](./PLAN.md) — <pending>
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
MD
cat > docs/plans/share-issues/BRIEF.md <<'MD'
# Brief

## Problem

Draft newsletter issues are private to the editor who created them. To get a review, editors
copy the text into an email, and the reviewer's notes come back detached from the issue.
Editors want to share a draft with named colleagues inside the backoffice.

## Who

Editors who write newsletter issues, and the colleagues who review them.

## Success

An editor shares a draft with one or more backoffice users, choosing whether each can only
view it or also edit it, in under a minute.

## Out of scope

Sharing with people outside the backoffice. Comment threads.
MD
cat > docs/plans/share-issues/ARCHITECTURE.md <<'MD'
# Architecture

## Extension points

A "Share" entity action on a newsletter issue in the Newsletters tree, opening a sidebar
modal. No new section or screen.

## Data model & persistence

`IssueShare` (IssueKey, UserKey, Access: View | Edit, SharedAt) in EF Core, SQL Server and
SQLite.

## Key decisions

- **Per-user access, not a public link.** A link would leak drafts outside the backoffice.
MD
cat > docs/plans/share-issues/SPEC.md <<'MD'
# Spec

## Management API surface

- `GET /newsletter/issues/{key}/shares` lists who an issue is shared with.
- `PUT /newsletter/issues/{key}/shares` replaces the list.

## Frontend components

### Share modal

<!-- Mockup still pending (`mockups/share-modal.html`); this phase isn't finished until it
     exists. -->

A sidebar modal titled "Share 'Spring sale 2027'". Fields:

- **People**: the backoffice users the issue is shared with. Add more; remove one.
- **Access**: one choice for everyone added: "Can view" or "Can edit".

Under the fields, a notice: "People you share with see the whole draft, including sections
that aren't scheduled yet." It should stand out from the fields, since it's the one thing
editors misjudge.

Footer: Cancel, and "Share" (primary). Shows two people already added, one with a long
display name.

## Non-functional targets

none — low traffic, no scale concerns.
MD
cat > docs/plans/share-issues/DECISION-LOG.md <<'MD'
# Decision log

- 02-11-2026 — Per-user access, not a public link (see ARCHITECTURE.md).
MD
