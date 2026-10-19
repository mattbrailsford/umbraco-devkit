#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.Webhooks

An Umbraco 17 package (C#). Trunk branch: `main`. Repo: `acme/Umbraco.Community.Webhooks` on
GitHub.
EOF
cat > COMMENTS.txt <<'EOF'
PR #58, repo acme/Umbraco.Community.Webhooks

Comment 1
  comment id: 2456781
  thread id:  PRRT_kwDOA1b2c384AbCd
  file: src/Umbraco.Community.Webhooks/WebhookDeliveryQueue.cs
  body: "This could throw if `delivery` is null — add a guard clause."
  status: fixed in the latest push (added a null check at the top of Enqueue)

Comment 2
  comment id: 2456782
  thread id:  PRRT_kwDOA1b2c384AbCe
  file: src/Umbraco.Community.Webhooks/WebhookDeliveryQueue.cs
  body: "Consider caching the sender lookup — it currently runs inside the retry loop."
  status: fixed in the latest push (moved the lookup outside the loop)

Comment 3
  comment id: 2456783
  thread id:  PRRT_kwDOA1b2c384AbCf
  file: src/Umbraco.Community.Webhooks/WebhookRetryPolicy.cs
  body: "Should DelayFor use async/await instead of returning a plain TimeSpan?"
  status: not applicable — DelayFor is a pure calculation with no I/O, explain why it stays
    synchronous
EOF
