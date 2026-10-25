#!/usr/bin/env bash
set -euo pipefail
p=docs/plans/scheduled-unpublish
mkdir -p $p
cat > $p/ARCHITECTURE.md <<'MD'
# Architecture: scheduled unpublish

A workspace view on documents sets an unpublish date; a background job unpublishes due
documents.

## Data model

<!-- TODO -->
MD
cat > $p/SPEC.md <<'MD'
# Spec: scheduled unpublish

## Settings

<!-- TODO -->
MD
cat > $p/design-notes.md <<'MD'
data
- new table myPackageScheduledUnpublish, migration AddScheduledUnpublish
- Id int PK identity
- ContentKey Guid not null, unique (one schedule per document)
- UnpublishDate DateTime not null, stored as UTC
- Reason nvarchar(500) nullable, shown in the workspace view
- CreatedBy int nullable (user id; null when set by the API with no user)
- CreatedUtc DateTime not null
- same table on SQL Server and SQLite, no provider-specific columns

settings (new, under Umbraco:MyPackage:ScheduledUnpublish)
- Enabled bool default true
- CheckIntervalMinutes int default 5, 1-60, how often the job looks for due documents
- KeepHistoryDays int default 30, finished schedules older than this are deleted
MD
