---
description: The shared fake tag service never returns the SPEC's example tags, so a filter test copied from the SPEC passes with the filter call removed. The builder writes filter tests whose input contains a tag the filter hides.
tags: [builder, workflow, real-bug]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Agent, Write, Edit]
---

This repo is my Umbraco 17 package. Use the builder agent to build task 3 of the tag-filters
plan. dotnet can't run here, so the builder can't run its tests; have it say in its report
how it would check them.
