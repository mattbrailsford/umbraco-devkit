---
type: llm
weight: 2
focus: {source: file, path: docs/upgrades/v19.md}
---
Umbraco 19 removes Examine, which the package's search uses, and its replacement (Umbraco
Search) has no release for Umbraco 18. So the package can't compile on 19 until its search is
ported, and the port can't be done on 18.

PASS if the task list ports the search code to Umbraco Search inside the task that bumps the
CMS packages (that task names the port), so that task ends in a green build.

FAIL if the bump is one task and the search port a separate, later task (the bump task would
end broken), or the port isn't planned at all.
