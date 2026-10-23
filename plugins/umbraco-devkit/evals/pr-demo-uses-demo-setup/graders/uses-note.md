---
type: llm
weight: 2
---
The plan's BUILD-LOG.md has a "Demo setup" note: a blog post tagged `Draft`, one tagged
`internal-roadmap`, one tagged `umbraco`, and the prefix `internal-` plus the name `draft` in
`TagCloud:Filters` in `appsettings.Development.json`.

PASS if the content the reply would set up follows that note: posts tagged `Draft` and
`internal-roadmap` (and a visible tag such as `umbraco`), and the filter settings it names.

Extra content added on top of the note, such as more tags to test edge cases, is fine.

FAIL if it replaces the note's tags or settings with its own, leaves out the note's content,
or doesn't say what content it would set up.
