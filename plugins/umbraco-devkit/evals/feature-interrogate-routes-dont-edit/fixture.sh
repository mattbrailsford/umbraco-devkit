#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.WebhookRetry

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`.
EOF
mkdir -p docs/plans/webhook-retry
cat > docs/plans/webhook-retry/README.md <<'EOF'
# Webhook retry

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — editors can retry failed webhook deliveries automatically
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — a retry queue plus a Management API endpoint for manual retry
3. [x] [SPEC.md](./SPEC.md) — retry policy and the manual-retry endpoint
4. [x] [STORIES.md](./STORIES.md) — two stories
5. [x] [PLAN.md](./PLAN.md) — four tasks
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
EOF
cat > docs/plans/webhook-retry/BRIEF.md <<'EOF'
# Webhook retry: brief

## Problem
A failed webhook delivery is dropped silently. Editors only find out when a third party
complains an update never arrived, then have to re-save content just to resend it.

## Who
Editors who configure webhooks, and the external systems that receive them.

## Success
A failed delivery retries automatically up to three times; editors can also trigger one
manual retry from the backoffice.

## Out of scope
Changing the webhook payload format. Delivery analytics.
EOF
cat > docs/plans/webhook-retry/ARCHITECTURE.md <<'EOF'
# Webhook retry: architecture

- `WebhookDeliveryQueue`: a background hosted service that retries a failed delivery up to
  three times, with a 1/5/15 minute backoff, writing each attempt to `WebhookDeliveryLog`.
- `WebhookRetryController` (Management API): `POST
  /umbraco/management/api/v1/webhook-retry/{deliveryId}`, triggers one manual retry for a
  delivery that's exhausted its automatic attempts.
- A new "Retry" button on the existing webhook delivery list screen calls the controller.
EOF
cat > docs/plans/webhook-retry/SPEC.md <<'EOF'
# Webhook retry: spec

- A failed delivery retries automatically up to three times, backoff 1/5/15 minutes.
- Every attempt (automatic or manual) is written to `WebhookDeliveryLog` with its outcome.
- After three failed automatic attempts, the delivery is marked `exhausted` and surfaces a
  manual "Retry" button on the delivery list screen.
- `POST /umbraco/management/api/v1/webhook-retry/{deliveryId}` triggers one manual retry for
  an `exhausted` delivery and returns its new status.

## Management API surface
`WebhookRetryController`: one `POST` action, above.

## Frontend components
A "Retry" button added to the existing webhook delivery list element.
EOF
cat > docs/plans/webhook-retry/STORIES.md <<'EOF'
# Webhook retry: stories

1. **Automatic retry.** Given a webhook delivery fails, when the backoff window passes, then
   it retries automatically, up to three times total.
2. **Manual retry.** Given a delivery is `exhausted`, when an editor clicks Retry on the
   delivery list screen, then one more attempt runs and the screen shows its new status.
EOF
cat > docs/plans/webhook-retry/PLAN.md <<'EOF'
# Webhook retry: plan

- [ ] T1 — story: 1 — depends-on: none — parallel-group: a
      Add `WebhookDeliveryLog` and the `exhausted` status to the delivery model.
      Acceptance: a migration adds the column; unit tests cover the new status transition.
- [ ] T2 — story: 1 — depends-on: T1 — parallel-group: b
      Add `WebhookDeliveryQueue` as a hosted service: retries a failed delivery on the
      1/5/15 minute backoff and logs each attempt.
      Acceptance: unit tests cover the backoff schedule and the exhausted transition.
- [ ] T3 — story: 2 — depends-on: T1 — parallel-group: b
      Add `WebhookRetryController` with the manual-retry `POST` action.
      Acceptance: unit tests pass.
- [ ] T4 — story: 2 — depends-on: T3 — parallel-group: c
      Add the "Retry" button to the webhook delivery list screen, calling T3's endpoint.
      Acceptance: unit tests cover the button's visibility for an `exhausted` delivery.
EOF
cat > docs/plans/webhook-retry/DECISION-LOG.md <<'EOF'
# Webhook retry: decision log
EOF
