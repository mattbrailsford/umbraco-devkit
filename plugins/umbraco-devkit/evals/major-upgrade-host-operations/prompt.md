---
description: "When the package plugs into another Umbraco product, major-upgrade's plan lists the host's operations on the package's types, by mode, for the smoke, and asks for a second demo site when an operation needs two environments."
tags: [major-upgrade, workflow, real-bug]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Umbraco Deploy 19.0.0-beta1 is now on the MyGet pre-release feed. Can you plan the update of
OrderExports.Deploy for it? Our current Deploy version is 18.1.0. Git, dotnet and the network
can't run here, so mark anything you can't look up as still to check. Write the upgrade
checklist and show me the plan before building anything.
