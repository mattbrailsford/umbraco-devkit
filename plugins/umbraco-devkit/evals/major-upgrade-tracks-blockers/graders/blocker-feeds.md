---
type: llm
weight: 2
focus:
  source: file
  path: docs/upgrades/v19.md
---
The setup: the package publishes all its packages, pre-releases included, to NuGet.org.
Umbraco Deploy has no 19 release on any feed. Umbraco Automate has 19.0.0-rc1 on the MyGet
pre-release feed only, so a package on NuGet.org that depends on it can't be restored by sites
using NuGet.org alone.

PASS if the upgrade file records both Deploy and Automate as blockers, and for each one says
where it is available now (Deploy: nowhere; Automate: MyGet only) and where it's needed (on
NuGet.org, or "on the feed our packages publish to"). Wording and layout are free.

FAIL if either is missing from the file, if Automate is treated as fine because a 19 rc1
exists (no mention that MyGet-only isn't enough for a NuGet.org release), or if the file
doesn't say which feed each one is needed on.
