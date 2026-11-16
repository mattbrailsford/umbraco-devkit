---
type: llm
focus: trace
---
Deploy is moving to a new major (19), so the connector may hit Deploy's breaking changes,
which are still unknown.

PASS if, before editing any `.csproj`, `.props` or `.cs` file, the answer works out what the
new major changes (Deploy 19's breaking changes or release notes, or marks that research as still
to do) and writes or shows a plan or checklist. Stopping to ask before changing code also
passes.

FAIL if the answer edits package versions or code before any plan, for example bumping
`Umbraco.Deploy.Infrastructure` to 19.0.0-beta1 and patching the connector straight away.
