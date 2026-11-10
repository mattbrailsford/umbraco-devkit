---
description: "Adding row editing to a dashboard whose Add button already opens its form sidebar at runtime."
tags: [umbraco-backoffice-ux, should-trigger]
# covers: ["Modals that edit something get a URL"]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, WebFetch]
---

My Umbraco 17 package has a Redirects dashboard (`client/src/redirects/redirects-dashboard.element.ts`)
that lists the saved redirect rules and has an "Add rule" button that opens the rule sidebar.
Editors now need to change existing rules too: clicking a row should open the same sidebar
filled in with that rule, and saving should update it through the repository.

There's no npm or network for packages here, so you can't install anything or run the build;
just make the code change.
