#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'EOF'
# MyCompany.Newsletter

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
EOF
p=docs/plans/subscriptions
mkdir -p $p/mockups
cat > $p/README.md <<'EOF'
# Subscriptions

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — editors can let members subscribe to topics
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — topics in an EF Core table, a Management API controller, two backoffice screens
3. [x] [SPEC.md](./SPEC.md) — topics dashboard and topic editor
4. [ ] [STORIES.md](./STORIES.md) — <pending>
5. [ ] [PLAN.md](./PLAN.md) — <pending>
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
EOF
cat > $p/BRIEF.md <<'EOF'
# Subscriptions: brief

## Problem
Members can't choose which newsletter topics they get, so they unsubscribe from everything.

## Who
Site members, and the editors who manage topics.

## Success
Unsubscribe rate drops by a third within three months of release.

## Out of scope
Paid subscriptions. Sending email (the existing sender does that).
EOF
cat > $p/ARCHITECTURE.md <<'EOF'
# Subscriptions: architecture

## Extension points
- A dashboard in the Newsletter section listing topics.
- A workspace for editing one topic.

## Data model
`Topic` (Id, Key, Name, Description, IsDefault) and `MemberTopic` (MemberKey, TopicKey), in
EF Core with SQL Server and SQLite migrations.

## Management API
`TopicController` under `newsletter/topics`: list, get, create, update, delete.
EOF
cat > $p/SPEC.md <<'EOF'
# Subscriptions: spec

## Management API
- `GET /newsletter/topics` returns all topics with their subscriber count.
- `GET /newsletter/topics/{key}` returns one topic.
- `POST`, `PUT`, `DELETE` on the same routes; delete is refused while a topic has subscribers.

## Frontend components

### Topics dashboard
![Topics dashboard mockup](./mockups/topics-dashboard.png)

A table of topics with name, subscriber count and a default flag. "Create topic" opens the
topic editor.

### Topic editor
A workspace with Name (required, max 100 characters), Description, and an "On by default for
new members" toggle. Save and Delete in the footer; Delete is disabled while the topic has
subscribers, with a tooltip saying why.
EOF
echo '<!doctype html><title>Topics dashboard</title>' > $p/mockups/topics-dashboard.html
printf '\x89PNG\r\n\x1a\n' > $p/mockups/topics-dashboard.png
cat > $p/DECISION-LOG.md <<'EOF'
# Decision log
EOF
