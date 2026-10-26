#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/notes
cat > docs/notes/delivery.md <<'MD'
how webhook delivery works in Acme.Webhooks

- on publish, ContentPublishedHandler writes one Delivery row per subscribed endpoint, status Pending
- DeliveryJob (background job, runs every 10s) picks up to 50 Pending rows, oldest first, marks them Sending
- POSTs the payload, timeout 15s
- 2xx -> Delivered
- anything else or timeout -> Failed, Attempts++
- Failed with Attempts < 5 -> Retrying, NextAttemptUtc = now + 2^Attempts minutes (2, 4, 8, 16)
- DeliveryJob also picks Retrying rows whose NextAttemptUtc has passed, back to Sending
- Failed with Attempts = 5 -> Dead. stays in table, shown red in the Deliveries dashboard, can be resent by hand (goes back to Pending, Attempts reset to 0)
- Delivered and Dead rows are deleted after 30 days by the cleanup job (runs nightly 02:00 server time)
- load balanced: only the SchedulingPublisher server runs DeliveryJob and cleanup
MD
