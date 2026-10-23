---
type: llm
weight: 2
---
The plan's BUILD-LOG.md has a "Demo setup" note: a blog post tagged `Draft`, one tagged
`internal-roadmap`, one tagged `umbraco`, and the prefix `internal-` plus the name `draft` in
`TagCloud:Filters` in `appsettings.Development.json`.

PASS if the content the reply would set up follows that note: posts tagged `Draft` and
`internal-roadmap` (and a visible tag such as `umbraco`), and the filter settings it names.

FAIL if it sets up different tags or settings of its own, or doesn't say what content it
would set up.
