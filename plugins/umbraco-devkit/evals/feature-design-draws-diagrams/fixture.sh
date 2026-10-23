#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# MyCompany.Newsletter

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`. Supports SQL
Server and SQLite. Stores its own data with EF Core.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
MD
mkdir -p docs/plans/subscriber-export src/MyCompany.Newsletter/Subscriptions
cat > docs/plans/subscriber-export/README.md <<'MD'
# Subscriber export

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — Mailing tools need a nightly list of who is subscribed to which topic.
2. [ ] [ARCHITECTURE.md](./ARCHITECTURE.md) — <pending>
3. [ ] [SPEC.md](./SPEC.md) — <pending>
4. [ ] [STORIES.md](./STORIES.md) — <pending>
5. [ ] [PLAN.md](./PLAN.md) — <pending>
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
MD
cat > docs/plans/subscriber-export/BRIEF.md <<'MD'
# Brief

## Problem

Sites that use the package send the actual emails from an external mailing tool. Today an
editor exports subscribers by hand from the backoffice each week, so the tool's lists go
stale. The mailing tool should pull, every night, the list of subscribed members and their
topics through an API, using an Umbraco API user.

Who: site developers who set up the mailing tool's sync job. Success: the tool's lists match
the site within a day, without an editor doing anything.

Constraints: the bigger customer sites have around 60,000 members, and several run on a
single small App Service plan that also serves the public site. The sync runs at night, but
those sites still get traffic then.

## Non-goals

- Pushing changes to the mailing tool (webhooks): pull only, for now.
- Importing unsubscribes back from the mailing tool.
MD
cat > docs/plans/subscriber-export/DECISION-LOG.md <<'MD'
# Decision log
MD
cat > src/MyCompany.Newsletter/Subscriptions/Subscription.cs <<'CS'
namespace MyCompany.Newsletter.Subscriptions;

public class Subscription
{
    public int Id { get; set; }
    public Guid MemberKey { get; set; }
    public int TopicId { get; set; }
    public DateTime CreatedUtc { get; set; }
}
CS
cat > src/MyCompany.Newsletter/Subscriptions/Topic.cs <<'CS'
namespace MyCompany.Newsletter.Subscriptions;

public class Topic
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public bool Retired { get; set; }
}
CS
