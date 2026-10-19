#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'EOF'
# Umbraco.Community.Webhooks

An Umbraco 17 package (C#). Trunk branch: `main`. Each feature gets its own git worktree
under `.worktrees/<feature-slug>`, so more than one is often checked out against this repo
at the same time.
EOF
mkdir -p src/Umbraco.Community.Webhooks
cat > src/Umbraco.Community.Webhooks/OrderService.cs <<'EOF'
namespace Umbraco.Community.Webhooks;

public class OrderService(IOrderRepository repository)
{
    public Order? GetById(int id) => repository.GetById(id);
}
EOF
