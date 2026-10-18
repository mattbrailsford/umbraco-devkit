---
type: llm
focus: trace
---
Context: Umbraco's `GlobalSetupTeardown` requires `appsettings.Tests.json` in the test run's
output folder. `Umbraco.Cms.Tests.Integration` adds that file to the project as content but
doesn't copy it to the output.

PASS if the test project makes sure `appsettings.Tests.json` ends up in the output folder:
an item in the `.csproj` for `appsettings.Tests.json` with `CopyToOutputDirectory`
(`PreserveNewest` or `Always`), whether the file is the package's or one the project adds.

FAIL if nothing copies `appsettings.Tests.json` to the output, if only
`appsettings.Tests.Local.json` is copied, or if no test project was written.
