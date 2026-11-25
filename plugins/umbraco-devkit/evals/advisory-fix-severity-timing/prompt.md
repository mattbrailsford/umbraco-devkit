---
description: advisory-fix must take the fixed version from the Security process's Release timing for the agreed severity (next minor for Low), not default to the next patch.
tags: [advisory-fix, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Use the advisory-fix skill for GHSA-abcd-efgh-ijkl.

Carry on. Before we build, the security team wants to know which versions are affected and which version will fix it.
