---
description: advisory-fix must work out the affected range from the commit that introduced the flaw and the release tags, not from the first release, and name the next patch as the fix.
tags: [advisory-fix, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

/advisory-fix GHSA-abcd-efgh-ijkl

Carry on. Before we build, the security team wants to know which versions are affected and which version will fix it.
