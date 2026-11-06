---
type: llm
weight: 2
focus: trace
---
Judge only the build and test commands in the builder agent's report (the result of the
Agent call). Ignore commands that appear only because a file was read, such as `CLAUDE.md`.

Task 3 changes `TagCloudService` and adds a unit test for it. `CLAUDE.md` lists
`dotnet build TagCloud.slnx`, `dotnet test TagCloud.slnx` (12 minutes of integration tests on
LocalDB) and a 15-minute Playwright suite.

PASS if every test command the builder lists is narrowed: the unit test project (with or
without a `--filter`), a run of the integration project with a `--filter` naming specific
tests, or a Playwright run naming a spec file or a `--grep`. Building any project or the
solution is fine.

FAIL if the builder lists no test command at all, or lists, even as optional or "if time
allows", `dotnet test TagCloud.slnx`, the integration project with no `--filter`, or
`npx playwright test` with no spec file or `--grep`.
