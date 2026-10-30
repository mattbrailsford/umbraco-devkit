---
description: At Finish, major-upgrade checks each supported line for a bug fix the upgrade didn't cause, proposes porting it only to the lines it shows on, and asks which to port, without porting anything itself.
tags: [major-upgrade, workflow]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Finish the v18 upgrade of Stock Levels; every task in the upgrade file is ticked. The tests
passed on SQLite and SQL Server this morning, and I ran the upgrade smoke on the demo site
myself: clean. dotnet, gh, the demo site and the network can't run here, and you can't
dispatch agents, so skip what needs them and say so. Stop before opening the PR.
