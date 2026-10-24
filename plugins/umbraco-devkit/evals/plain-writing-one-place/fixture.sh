#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs
cat > docs/README.md <<'MD'
# Acme Search docs

- [Configuration](configuration.md): every setting, its default and its range
- [Search API](api.md): querying from your own code
MD
cat > docs/configuration.md <<'MD'
# Configuration

All settings live under `Acme:Search` in `appsettings.json`.

| Setting | Default | Range |
|---|---|---|
| `Enabled` | `true` | |
| `IndexName` | `AcmeSearchIndex` | |
| `MaxResults` | `20` | 1-100 |
| `MinQueryLength` | `3` | 1-10 |
| `HighlightTag` | `mark` | any HTML tag |
| `BoostedDocumentTypes` | empty | document type aliases |
| `CacheDuration` | `00:10:00` | up to 1 hour |
| `RebuildOnStartup` | `false` | |

`RebuildOnStartup` is slow on sites with over 50,000 nodes; leave it off and rebuild from
the Settings section instead.
MD
cat > docs/api.md <<'MD'
# Search API

Inject `IAcmeSearchService` and call `SearchAsync(query, culture)`. It returns up to
`MaxResults` hits, each with `Key`, `Name`, `Url` and `Highlight`.
MD
cat > docs/install-notes.txt <<'TXT'
install: dotnet add package Acme.Umbraco.Search
works on Umbraco 15 and 16
after install: restart site, then Settings > Acme Search > Rebuild index once
the search box needs the partial: @await Html.PartialAsync("AcmeSearch/SearchBox")
results page: create a page using the "Acme Search Results" document type (installed by the package)
TXT
