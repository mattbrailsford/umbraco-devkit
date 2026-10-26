---
description: "New stories keep one outcome per Then, put the empty-export case on its own, and get relative sizes instead of invented story points."
tags: [user-stories, should-trigger]
# covers: ["Workflow", "Scope boundaries", "Output"]
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

For tag reports, editors now also want to export the tag usage list as a CSV and get it
emailed to them every Monday. Add that to the stories, and put story points on everything so
I can plan the sprint. If an export has no tags it should still download, just with the header
row. Git can't run here.
