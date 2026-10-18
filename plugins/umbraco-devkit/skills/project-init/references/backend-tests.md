# Step 5: Backend tests

## Detect

Look for test projects in the solution (`*.Tests*.csproj`, or any project referencing
`Microsoft.NET.Test.Sdk`) and note the framework from their package references: NUnit, xUnit
or MSTest. If one exists, keep it. `bdd-specs` writes tests in whatever framework the project
already has.

## Default if missing: NUnit

Ask first. NUnit is the default because Umbraco CMS uses it, and so do Umbraco's own test
helper packages. A project on xUnit can't use those helpers.

Offer two projects, as separate questions. Most packages want both.

**Unit tests: `<Package>.Tests.Unit`**
```bash
dotnet new nunit -n <Package>.Tests.Unit -o tests/<Package>.Tests.Unit
dotnet sln add tests/<Package>.Tests.Unit
dotnet add tests/<Package>.Tests.Unit reference <path to the package project>
dotnet add tests/<Package>.Tests.Unit package Moq
```
- Optional: `Umbraco.Cms.Tests` (NuGet) adds builders for content, document types, users and
  similar. Use the same version as the project's `Umbraco.Cms` reference.

**Integration tests: `<Package>.Tests.Integration`**
- Same `dotnet new nunit` steps, plus `Umbraco.Cms.Tests.Integration` at the project's CMS
  version.
- It provides `UmbracoIntegrationTest`, a base class that starts real Umbraco with real DI and
  a test database. Tests inherit it, set the database mode with
  `[UmbracoTest(Database = UmbracoTestOptions.Database.NewSchemaPerFixture)]`, register the
  package in `CustomTestSetup(IUmbracoBuilder builder)`, and resolve services with
  `GetRequiredService<T>()`.
- The test database is set in `appsettings.Tests.json` under `Tests:Database`:
  `"DatabaseType": "SQLite"` by default, or SQL Server via `"LocalDb"` /
  `SQLServerMasterConnectionString`. Running the same tests on SQL Server is the automated
  version of `ef-core-data`'s "SQLite tests don't prove SQL Server" check.
- Writing tests on it is `umbraco-testing`'s job: the test host differs from a real site
  in ways that let a test pass without exercising the package.
- The CMS's own integration project also has an assembly-level `[SetUpFixture]`
  (`GlobalSetupTeardown.cs`) that loads that settings file. Check
  `tests/Umbraco.Tests.Integration/` in the CMS repo, at the release tag the project targets,
  for what a consuming project has to provide. Copy what's there; don't guess.

If the project uses `Directory.Packages.props`, add the versions there, not in each `.csproj`.

## Check

`dotnet build` and `dotnet test` both succeed (zero tests is fine). Don't add sample tests.

## Record

Add the `dotnet test` command to `CLAUDE.md`'s "Build & test" section. If the integration
project can switch to SQL Server, note how (which setting, which connection string source).
Never commit a connection string with a password in it.
