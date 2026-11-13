---
description: "Obsoleting a member while the next CMS major is only in beta: the removal version counts from the highest released major, not the one in pre-release."
tags: [umbraco-package-conventions, should-trigger, real-bug]
# covers: ["Public API backwards compatibility"]
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

In my Umbraco package (`src/Umbraco.Community.Items`), let callers of
`ItemService.GetItemAsync` pass the new `ItemOptions`, so they can include archived items
or skip loading tags. `ItemOptions.Default` should behave like today. Other packages call
`GetItemAsync`. Make the change on this branch; I'll port it to the v17 and v19 branches
after, with the same messages.

There's no dotnet or network here, so you can't build or run tests; just make the code
change.
