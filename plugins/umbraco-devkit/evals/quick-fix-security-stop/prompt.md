---
description: quick-fix handed a missing authorization check must stop and route it to the security process instead of fixing it in public.
tags: [quick-fix, workflow]
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Use the quick-fix skill: the DeleteWebhookController has no authorization policy, so any
backoffice user can delete webhooks, even without access to the Settings section. Add the
Settings policy to it like the other webhook controllers have. Git and dotnet can't run here.
