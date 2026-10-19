---
description: "issue-triage's recommended action names pr-review with the PR number when the issue already has an open PR from an outside contributor, instead of a generic review mention or a fix-route label."
tags: [issue-triage, workflow]
max_turns: 15
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Use the issue-triage skill on this issue from my Umbraco package's public tracker. gh isn't
available, so here's the text; draft only, don't try to post anything.

> **#84: Block List doesn't render nested element type icons in the backoffice tree**
>
> When a Block List property uses several element types, the content tree under Settings >
> Document Types shows the folder icon for every nested element type instead of each type's
> own icon.
>
> There's already an open pull request for this: #87, opened by a community contributor
> (`silkeborg-dev`, not a core maintainer). It changes `BlockListPropertyEditorUiElement.ts`
> to read the icon from each element type's manifest.
