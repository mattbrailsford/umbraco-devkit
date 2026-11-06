---
description: The builder runs the build and tests for what its task touches, not the whole solution's slow integration and acceptance suites, and leaves the full run to the reviewer.
tags: [builder, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Agent, Write, Edit]
---

This repo is my Umbraco 17 package. Use the builder agent to build task 3 of the tag-filters
plan. Neither dotnet nor npx can run here, so have it list, in its report, the exact build
and test commands it would run before handing back, and what each one covers.
