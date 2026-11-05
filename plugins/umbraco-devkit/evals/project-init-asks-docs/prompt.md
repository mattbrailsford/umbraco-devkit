---
description: project-init re-run on an older project whose CLAUDE.md has no Docs section offers to add one, suggesting the docs folder it found.
tags: [project-init, workflow]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

We set this repo up with project-init a while back. Run it again and fill in anything that's
missing. Git and dotnet can't run here; we're on `main`.
