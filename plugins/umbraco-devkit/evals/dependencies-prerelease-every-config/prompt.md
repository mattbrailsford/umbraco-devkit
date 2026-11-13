---
description: "Moving to a CMS RC that's only on Umbraco's MyGet feed: the lock files are rebuilt and proved with a locked restore from a cleared cache."
tags: [umbraco-dependencies, should-trigger, real-bug]
# covers: ["Which CMS version: the floor"]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, WebFetch]
---

Umbraco 19.0.0-rc1 is out. The CMS and Umbraco.Licenses rc1 builds are only on Umbraco's
MyGet pre-release feed for now, both NuGet and npm. Move our v19 line from beta1 to rc1 so
it restores and CI passes. dotnet, npm and git can't run here; tell me anything I need to
run myself.
