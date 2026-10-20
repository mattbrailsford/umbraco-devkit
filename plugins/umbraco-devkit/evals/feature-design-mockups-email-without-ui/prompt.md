---
description: feature-design must mock up a user-facing email the feature sends, even for a feature with no backoffice screens of its own.
tags: [feature-design, workflow]
# covers: ["Mockup a user-facing email"]
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, WebFetch]
---

Use the feature-design skill for the export-ready-email feature. Git can't run here; we're on
`main`. There's no browser available to run a local server or take a screenshot, so draw the
email as its mockup HTML file. Don't ask me questions; make reasonable assumptions and note
them.
