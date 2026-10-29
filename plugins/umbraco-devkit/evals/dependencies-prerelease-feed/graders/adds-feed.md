---
type: llm
weight: 3
focus: trace
---
Umbraco.Licenses has no 19.x release on nuget.org yet. Its 19 pre-release (`19.0.0-beta`) is
only on Umbraco's pre-release feed on MyGet
(`https://www.myget.org/F/umbracoprereleases/api/v3/index.json`). The repo's `NuGet.config`
lists only nuget.org.

PASS if the change adds Umbraco's pre-release MyGet feed to `NuGet.config` (any URL under
`myget.org/F/umbracoprereleases`), or, if it can't confirm where the package lives, tells the
user that Umbraco product pre-releases may only be on that feed and it needs adding.

FAIL if the feed isn't added or named, for example just setting Umbraco.Licenses to a 19
pre-release version and assuming nuget.org has it.
