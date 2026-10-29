---
description: "Targeting a CMS beta; another Umbraco product's matching pre-release may only be on Umbraco's pre-release feed, which the repo and its consumers then need."
tags: [umbraco-dependencies, should-trigger]
# covers: ["Which CMS version: the floor"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

We're starting the v19 line of our package against Umbraco 19.0.0-beta1. Update the
packages so it restores against the beta, Umbraco.Licenses included, and draft the
"Installing" note for the v19 pre-release's README. dotnet and the network can't run here.
