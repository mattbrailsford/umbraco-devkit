---
description: When the target major removes a subsystem the package uses and its replacement already exists on the current major, major-upgrade ports to it first, behind the package's own abstraction, as its own task before the bump.
tags: [major-upgrade, workflow]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Upgrade ProductFinder to Umbraco 19. Target `release-19.0.0`; the docs say 18.x upgrades
straight to 19, and it has no other Umbraco package dependencies. Git, gh, dotnet and the
network can't run here, and there's no CMS clone. One break we already know about: v19
removes Examine, and search moves to Umbraco Search (the `Umbraco.Cms.Search.*` packages).
Umbraco Search already ships a release for Umbraco 18 too. Leave the rest of the CMS
breaking-change research marked as still to do. We're on `main`, one version line, and the
package version follows the CMS major. Write the upgrade checklist and show me the plan
before building anything.
