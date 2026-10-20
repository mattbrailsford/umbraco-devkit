#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# MyCompany.Newsletter

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
MD
mkdir -p docs/plans/export-ready-email src/MyCompany.Newsletter/Export
cat > docs/plans/export-ready-email/README.md <<'MD'
# Export ready email

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — email the editor when their subscriber export is ready
2. [ ] [ARCHITECTURE.md](./ARCHITECTURE.md) — <pending>
3. [ ] [SPEC.md](./SPEC.md) — <pending>
4. [ ] [STORIES.md](./STORIES.md) — <pending>
5. [ ] [PLAN.md](./PLAN.md) — <pending>
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
MD
cat > docs/plans/export-ready-email/BRIEF.md <<'MD'
# Brief

## Problem

Editors can already trigger a subscriber export from the existing Members dashboard (no new
screen needed there). For a big site this can take several minutes to generate, so today the
editor has to keep the tab open and guess when it's done, or refresh repeatedly. There's no
new backoffice screen in this feature — the trigger button and the dashboard both already
exist — but once the export file is ready, the editor needs to be told, and given a link to
download it, without sitting there waiting.

## Who

Editors who export subscriber lists, on sites with enough members that generation isn't
instant.

## Success

An editor can start an export, close the tab, and get an email with a download link as soon
as it's ready, instead of babysitting the dashboard.

## Out of scope

Scheduling exports in advance. Exporting anything other than the current subscriber list.
MD
cat > docs/plans/export-ready-email/DECISION-LOG.md <<'MD'
# Decision log
MD
cat > src/MyCompany.Newsletter/Export/SubscriberExportJob.cs <<'CS'
namespace MyCompany.Newsletter.Export;

public class SubscriberExportJob
{
    public Guid Id { get; set; }
    public Guid RequestedByUserKey { get; set; }
    public string Status { get; set; } = "Pending"; // Pending, Ready, Failed
    public string? FileUrl { get; set; }
    public DateTime RequestedUtc { get; set; }
}
CS
