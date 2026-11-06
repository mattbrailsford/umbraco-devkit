---
description: feature-design screenshots a mockup taller than the 1440×900 viewport in full, so no section is cut off at the bottom.
tags: [feature-design, workflow, real-bug]
# covers: ["Mockup each screen"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Use the feature-design skill on the usage-dashboard plan. I've already drawn
`mockups/usage.html` and I'm happy with the markup, so don't change it. Screenshot it and show
it to me so I can sign it off; leave the rest of the design for later. Git can't run here; we're
on `main`. Full Chrome won't start here, but the headless shell does:
`tools/chrome-headless-shell/chrome-headless-shell`.
Python 3 and Node are available.
