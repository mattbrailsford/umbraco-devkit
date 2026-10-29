#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# Umbraco.Community.Webhooks

An Umbraco 17 package (C# plus a Lit backoffice client) that sends webhooks when content is
published. Sites using it are often load balanced.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`.
MD
mkdir -p docs/plans/webhook-delivery
cat > docs/plans/webhook-delivery/ARCHITECTURE.md <<'MD'
# Webhook delivery: architecture

## Extension points

A `ContentPublishedNotification` handler and an `IRecurringBackgroundJob`. Both are
registered by `WebhooksComposer`.

## Delivery

<!-- TODO: write this section -->

## Data model & persistence

EF Core tables `WebhookOutbox` and `WebhookLog`, SQL Server and SQLite.
MD
cat > docs/plans/webhook-delivery/design-notes.md <<'MD'
Notes from the design call (raw):

- publish handler runs on whichever server handled the publish. it does NOT send. it inserts
  one WebhookOutbox row per subscribed endpoint, same scope as the publish.
- WebhookDeliveryJob (IRecurringBackgroundJob), every 10s, only on the SchedulingPublisher
  server. subscriber servers skip it.
- job picks due rows: Status = Pending and NextAttemptAt <= now.
- POST the payload to the endpoint url with HttpClient.
- 2xx -> mark Delivered + write a WebhookLog entry.
- non-2xx or timeout -> if attempts < 5: attempts + 1, NextAttemptAt = exponential backoff,
  stays Pending (next run picks it up again). at 5 attempts: DeadLettered + WebhookLog entry.
- backoffice dashboard "Webhook deliveries" reads WebhookLog.
MD
