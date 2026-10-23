---
description: when the user chooses a stopgap, quick-fix marks it in the code and drafts a tracker issue for the proper fix without creating it.
tags: [quick-fix, workflow]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Use the quick-fix skill: since guest checkout went live, OrderEmailBuilder.Build throws a
NullReferenceException for guest orders, because guest orders have no Customer. We know the
proper fix is storing guest buyer details on Order, and we'll do that properly later. For
now, make OrderEmailBuilder skip guest orders so it stops crashing. Git, gh and dotnet can't
run here.
