#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# MyCompany.Newsletter

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
MD
mkdir -p docs/plans/routing-rule-editor/mockups src/MyCompany.Newsletter/Routing
cat > docs/plans/routing-rule-editor/README.md <<'MD'
# Routing rule editor

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — let editors add and edit link-tracking routing rules
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — a panel on the existing Redirects settings screen
3. [x] [SPEC.md](./SPEC.md) — the add/edit rule panel; one mockup still pending
4. [ ] [STORIES.md](./STORIES.md) — <pending>
5. [ ] [PLAN.md](./PLAN.md) — <pending>
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
MD
cat > docs/plans/routing-rule-editor/BRIEF.md <<'MD'
# Brief

## Problem

Newsletter links are tracked through a redirect so clicks can be counted, but every routing
rule has to be added by a developer through a config file today. Editors want to add or edit
a rule themselves, without waiting on a release. The existing Redirects settings screen
already lists rules and already supports deleting one — this feature only adds the missing
"add/edit a rule" panel.

## Who

Editors who build newsletter issues and want to track which links get clicked.

## Success

An editor can add or edit a routing rule themselves from the existing Redirects screen, with
no developer involved.

## Out of scope

The rule list screen and deleting a rule (both already exist). Importing config-file rules in
bulk.
MD
cat > docs/plans/routing-rule-editor/ARCHITECTURE.md <<'MD'
# Architecture

## Extension points

A new "Add rule" button and a per-row "Edit" action on the existing Redirects settings
screen, each opening the same sidebar panel. No new section or screen.

## Data model & persistence

`RoutingRule` (Key, Name, MatchPattern, DestinationUrl, Priority) in EF Core, SQL Server and
SQLite, alongside the existing redirect rule storage.

## Connected systems

None — this is a Settings-only addition with no public-facing behaviour change beyond what
redirects already do.

## Key decisions

- **A panel on the existing screen, not a new one.** The Redirects screen already lists and
  deletes rules; duplicating that as a new screen would fork the two representations. Rejected
  alternative: a dedicated "Routing rules" section.
MD
cat > docs/plans/routing-rule-editor/SPEC.md <<'MD'
# Spec

## Management API surface

- `POST /newsletter/routing-rules` creates a rule. `PUT /newsletter/routing-rules/{key}`
  updates one. Both validate that `MatchPattern` isn't already used by another rule.

## Frontend components

### Add/edit routing rule

<!-- Mockup still pending (`mockups/routing-rule-form.html`); this phase isn't finished until
     it exists. -->

A sidebar panel opened from "Add rule" (empty fields) or a row's "Edit" action (filled in).
Fields: Name (required), Link pattern (required, help text explains `*` wildcard matching),
Destination (required, a full web address), Priority (number; lower numbers win when more
than one rule matches). Close discards changes; Save validates and, on a duplicate match
pattern, keeps the panel open with that one field flagged invalid ("This pattern is already
used by another rule.").

## Non-functional targets

none — Settings-only, low traffic, no scale concerns.
MD
cat > docs/plans/routing-rule-editor/DECISION-LOG.md <<'MD'
# Decision log

- 19-10-2026 — A panel on the existing Redirects screen, not a new section (see
  ARCHITECTURE.md).
MD
cat > src/MyCompany.Newsletter/Routing/RoutingRule.cs <<'CS'
namespace MyCompany.Newsletter.Routing;

public class RoutingRule
{
    public Guid Key { get; set; }
    public string Name { get; set; } = "";
    public string MatchPattern { get; set; } = "";
    public string DestinationUrl { get; set; } = "";
    public int Priority { get; set; }
}
CS
