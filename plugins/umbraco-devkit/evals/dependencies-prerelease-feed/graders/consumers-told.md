---
type: llm
weight: 2
focus: trace
---
Sites installing this package's v19 pre-release will also have to restore Umbraco.Licenses'
pre-release, which isn't on nuget.org.

PASS if the drafted "Installing" note tells consumers to add Umbraco's pre-release feed
(`myget.org/F/umbracoprereleases`) to their own NuGet sources.

FAIL if the note doesn't mention a feed consumers need, or only says to install from nuget.org.
