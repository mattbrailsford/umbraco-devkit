#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# MyCompany.Newsletter

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
MD
mkdir -p docs/plans/delivery-retry src/MyCompany.Newsletter/Delivery
cat > docs/plans/delivery-retry/README.md <<'MD'
# Delivery retry

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — let editors see and retry failed newsletter deliveries
2. [ ] [ARCHITECTURE.md](./ARCHITECTURE.md) — <pending>
3. [ ] [SPEC.md](./SPEC.md) — <pending>
4. [ ] [STORIES.md](./STORIES.md) — <pending>
5. [ ] [PLAN.md](./PLAN.md) — <pending>
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
MD
cat > docs/plans/delivery-retry/BRIEF.md <<'MD'
# Brief

## Problem

When a newsletter issue fails to reach some members (a bounced address, a full mailbox, a
temporary SMTP error), editors have no way today to see who was missed or resend to just
them. They either resend the whole issue to everyone — spamming the members who already got
it — or write the failures down by hand from the mail server logs when a member complains
they didn't receive it.

## Who

Editors who send newsletter issues, and support staff who field "I didn't get this week's
email" questions and need to check one member's delivery history without asking a developer.

## Success

An editor can see, per issue, who failed and why, select some or all of them, and retry
delivery to just those members. Support can open one member and see their full delivery
history across every issue they were sent.

## Out of scope

Automatic/scheduled retries — this is a manual, editor-triggered action for now. Changing
the send pipeline itself (how an issue is composed or queued).
MD
cat > docs/plans/delivery-retry/DECISION-LOG.md <<'MD'
# Decision log
MD
cat > src/MyCompany.Newsletter/Delivery/Delivery.cs <<'CS'
namespace MyCompany.Newsletter.Delivery;

public class Delivery
{
    public int Id { get; set; }
    public int IssueId { get; set; }
    public Guid MemberKey { get; set; }
    public string Status { get; set; } = "Pending"; // Sent, Failed, Retried
    public string? FailureReason { get; set; }
    public DateTime SentUtc { get; set; }
}
CS
