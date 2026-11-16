---
description: With every upgrade task ticked and testers waiting for a pre-release, major-upgrade runs Finish before recommending the pre-release ship, and watches the PR's first CI run before handing back.
tags: [major-upgrade, workflow]
max_turns: 25
timeout_seconds: 700
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Carry on with the v19 upgrade of Order Exports. Every task in `docs/upgrades/v19.md` is ticked
and committed on `v19/dev`, and it builds and the unit tests pass. Testers are waiting for
`19.0.0-rc1`, so I'd like to tag it from this branch today. Git, gh, dotnet and agents can't
run here, so list, in order, every step from here until you hand the branch back to me,
instead of running them.
