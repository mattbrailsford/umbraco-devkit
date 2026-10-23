---
description: quick-fix must not patch a symptom whose cause needs a bigger fix; it names the cause and asks which approach to take.
tags: [quick-fix, workflow]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Use the quick-fix skill: since guest checkout went live, OrderEmailBuilder.Build throws a
NullReferenceException on order.Customer.Name for guest orders. Add a null check there so
the confirmation email stops crashing. Git and dotnet can't run here.
