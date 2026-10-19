#!/usr/bin/env bash
set -euo pipefail
mkdir -p .claude/memory
cat > .claude/memory/README.md <<'MD'
# Project memory

Durable, project-wide facts that don't belong to one directory and would bloat the root
`CLAUDE.md` if written there permanently.

**Use a nested `CLAUDE.md` instead when the fact is scoped to one directory or module** — a
rule only true inside `src/Migrations/`, say. Claude reads the nearest `CLAUDE.md` walking up
from whatever it's editing; a file in here doesn't get picked up that way, so directory-scoped
facts belong there, not here.

## Types

- `decision` — a standing, project-wide call (CMS major version(s) targeted, database
  provider(s) supported, deploy target, an architectural decision from `feature-design` that
  outlives the feature it came from). Written by `feature-explore`/`feature-design` when a decision
  isn't scoped to just the feature being worked on.
- `gotcha` — a correction learned the hard way, usually from a `reviewer` FAIL that revealed a
  rule the `builder` should already have followed. Written by `feature-build` so the next
  task doesn't repeat the same mistake.
- `reference` — a pointer to an external system relevant to this project (issue tracker,
  staging environment, a design doc).

## Format

One file per memory, kebab-case name, plus a one-line entry in `MEMORY.md` (the index):

```md
---
name: kebab-slug
description: one-line, specific enough to judge relevance later
type: decision | gotcha | reference
---

The fact or rule, then:

**Why:** the reasoning or incident that produced it.
**How to apply:** when this should change what an agent does.
```

Don't duplicate what's already in a skill, a stack-convention skill, or a directory's own
`CLAUDE.md` — this folder is for facts specific to *this* project that would otherwise get
re-decided or re-broken every few features.
MD
cat > .claude/memory/MEMORY.md <<'MD'
# Memory index

One line per file in this folder, newest relevant first. See `README.md` for the format.
MD
mkdir -p src/Acme.Package
cat > src/Acme.Package/OrderService.cs <<'CS'
namespace Acme.Package;

public sealed class OrderService
{
    public decimal GetTotalAsync(int orderId) => 0m;
}
CS
