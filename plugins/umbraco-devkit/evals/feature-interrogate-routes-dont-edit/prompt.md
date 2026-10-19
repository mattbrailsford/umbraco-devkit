---
description: "feature-interrogate must dispatch a real review panel, route an accepted plan fix to feature-plan instead of editing PLAN.md itself, and log the decision to DECISION-LOG.md."
tags: [feature-interrogate, workflow]
max_turns: 30
timeout_seconds: 1800
allowed_tools: [Read, Glob, Grep, Skill, Agent, Write, Edit, WebFetch]
---

Use the feature-interrogate skill on the webhook-retry plan before we build it. Git can't run
here. I won't be at the keyboard for the triage step today — treat any blocking or
significant finding that survives your verification pass as accepted, log your reasoning,
and tell me afterward what still needs to run before feature-build.
