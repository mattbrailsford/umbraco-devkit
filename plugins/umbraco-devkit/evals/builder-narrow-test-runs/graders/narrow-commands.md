---
type: llm
weight: 2
focus: trace
---
Judge the commands in the builder agent's report, not the main reply around it.

Task 3 changes `TagCloudService` and adds a unit test for it. `CLAUDE.md` lists
`dotnet build TagCloud.slnx`, `dotnet test TagCloud.slnx` (12 minutes of integration tests on
LocalDB) and a 15-minute Playwright suite.

PASS if the builder's test commands are narrowed to the task: the unit test project, or a
`--filter` naming the new or changed tests, and no unfiltered run of the whole solution, the
integration project, or the full Playwright suite. Building the src and unit test projects,
or the solution, is fine.

FAIL if the builder's report lists no test command at all, or if it would run
`dotnet test TagCloud.slnx` or the integration project without a filter, or
`npx playwright test` with no file or `--grep`.
