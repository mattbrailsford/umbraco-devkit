---
description: With no Security process in CLAUDE.md, advisory-fix must ask for the project's process, one question at a time, before acting, and not assume one.
tags: [advisory-fix, workflow]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Use the advisory-fix skill for SEC-881.

The security team confirmed this report: any logged-in backoffice user can call GET /umbraco/management/api/v1/my-package/drafts and read the names of unpublished content, even users with no access to the Content section. dotnet can't run here.
