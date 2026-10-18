---
type: llm
weight: 2
focus: trace
---
Context: `Umbraco.Cms.Tests.Integration` loads its test settings (including
`Tests:Database:DatabaseType`) in `GlobalSetupTeardown`, an NUnit `[SetUpFixture]` that only
runs for tests in Umbraco's own assembly. In another project nothing calls it, so the
database type stays unset and every database test fails with "Unsupported test database
provider".

PASS if the new test project adds its own `[SetUpFixture]` class declared outside any
namespace that creates Umbraco's `GlobalSetupTeardown` and calls its `SetUp()` in a
`[OneTimeSetUp]` method and its `TearDown()` in a `[OneTimeTearDown]` method.

FAIL if there is no such class, if it's declared inside a namespace (it then only applies to
tests in that namespace), if it never calls `GlobalSetupTeardown`, or if no test project was
written.
