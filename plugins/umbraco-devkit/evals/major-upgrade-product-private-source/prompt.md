---
description: "For another Umbraco product's new major, when the product's source is private and it has no release, major-upgrade finds the breaks in its public issue tracker by the package's own name, and says which sources it couldn't read."
tags: [major-upgrade, workflow, real-bug]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Umbraco Deploy 19.0.0-beta1 is now on the MyGet pre-release feed. Can you plan the update of
OrderExports.Deploy for it? Our current Deploy version is 18.1.0. dotnet, git clone and the
network can't run here. The real `gh` can't reach GitHub, so use `./.tools/gh` in its place.
Write the upgrade checklist and show me the plan before building anything.
