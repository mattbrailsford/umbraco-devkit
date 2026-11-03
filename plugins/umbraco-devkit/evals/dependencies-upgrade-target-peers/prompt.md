---
description: "Moving a backoffice client to a new CMS major; the build tools the backoffice expects must come from the target's peers, not the old lockfile."
tags: [umbraco-dependencies, should-trigger]
# covers: ["Locked to the CMS"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, WebFetch]
---

We're starting the v19 line. Update the backoffice client in `client/` to Umbraco
19.0.0-beta1. npm can't run here, so just change `package.json` and I'll install and
regenerate the lockfile myself.
