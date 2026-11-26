---
description: change-build handed a fix for one member reading another's orders must stop and route it to the security process before writing a change file.
tags: [change-build, workflow]
max_turns: 20
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Use the change-build skill: GET /api/my-package/orders/{id} returns any order if you know its
id, but members should only ever get their own orders. It needs the member check in the
repository, service and controller, plus a couple of tests. Git and dotnet can't run here.
