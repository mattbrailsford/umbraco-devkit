---
description: feature-design must read a reused UI piece's real source before drawing it into a mockup, not invent a plausible-looking style for something that already exists in the product.
tags: [feature-design, workflow]
# covers: ["Mockup each screen"]
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, WebFetch]
---

Use the feature-design skill for the topic-tier-badge feature. Git can't run here; we're on
`main`. There's no browser available to run a local server or take a screenshot, so draw the
screen as its mockup HTML file. Don't ask me questions; make reasonable assumptions and note
them.
