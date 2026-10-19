#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.Webhooks

An Umbraco 17 package (C#). Trunk branch: `main`. No plan-folder pipeline here — just
short-lived branches and PRs opened straight off `main`, or off another open branch when one
PR builds on another.
EOF
mkdir -p src/Umbraco.Community.Webhooks

# ---- state as it is on webhook-delivery-queue (PR #142, not yet merged into main) ----
cat > src/Umbraco.Community.Webhooks/WebhookDeliveryQueue.cs <<'EOF'
namespace Umbraco.Community.Webhooks;

public class WebhookDeliveryQueue(IWebhookSender sender)
{
    private readonly Queue<WebhookDelivery> _queue = new();

    public void Enqueue(WebhookDelivery delivery) => _queue.Enqueue(delivery);

    public async Task ProcessAsync(CancellationToken token)
    {
        while (_queue.TryDequeue(out var delivery))
        {
            await sender.SendAsync(delivery, token);
        }
    }
}
EOF
git add -A && git commit -qm "feat(webhooks): add delivery queue (PR #142, on main)"

# ---- the webhook-retry-backoff branch's own changes, stacked on top of the above ----
cat > src/Umbraco.Community.Webhooks/WebhookRetryPolicy.cs <<'EOF'
namespace Umbraco.Community.Webhooks;

public class WebhookRetryPolicy(int maxAttempts = 5)
{
    public TimeSpan DelayFor(int attempt) =>
        TimeSpan.FromSeconds(Math.Pow(2, Math.Min(attempt, maxAttempts)));
}
EOF
cat > src/Umbraco.Community.Webhooks/WebhookDeliveryQueue.cs <<'EOF'
namespace Umbraco.Community.Webhooks;

public class WebhookDeliveryQueue(IWebhookSender sender, WebhookRetryPolicy retryPolicy)
{
    private readonly Queue<WebhookDelivery> _queue = new();

    public void Enqueue(WebhookDelivery delivery) => _queue.Enqueue(delivery);

    public async Task ProcessAsync(CancellationToken token)
    {
        while (_queue.TryDequeue(out var delivery))
        {
            var attempt = 0;
            while (true)
            {
                try
                {
                    await sender.SendAsync(delivery, token);
                    break;
                }
                catch (WebhookSendException) when (attempt < 5)
                {
                    await Task.Delay(retryPolicy.DelayFor(attempt++), token);
                }
            }
        }
    }
}
EOF
# git can't run inside the eval sandbox, so hand over the branch diff as a file.
git add -A && git diff --cached > CHANGE.diff && git reset -q --hard
cat > COMMITS.txt <<'EOF'
f3a9c21 feat(webhooks): add exponential backoff retry policy
EOF
