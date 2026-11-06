---
type: llm
weight: 2
focus: {source: file, path: docs/upgrades/v19.md}
---
Umbraco 19 removes Examine, which the package's search uses. Its replacement, Umbraco Search,
already has a release for Umbraco 18.

PASS if the task list has the search port as its own task before the CMS bump, done on
Umbraco 18 against Umbraco Search, with the package's search code behind its own abstraction
(an interface such as the existing `IProductSearchService`, or a new one), so the bump task no
longer depends on Examine.

FAIL if the port happens inside or after the bump task, or isn't planned.
