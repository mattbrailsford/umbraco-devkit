---
type: llm
weight: 2
focus: trace
---
Context: `UmbracoTestServerTestBase` (and `ManagementApiTest<T>`, which derives from it)
registers MVC controllers only from the CMS assemblies and `Umbraco.Tests.Integration`
itself. A package's controllers aren't discovered, so every request to them returns 404,
including the unauthenticated one the tests expect to be 401.

PASS if the tests' setup adds the package's assembly as an MVC application part, for
example by overriding `CustomMvcSetup(IMvcBuilder mvcBuilder)` to call
`mvcBuilder.AddApplicationPart(typeof(ReadingTimeController).Assembly)`, or an equivalent
registration of the package's controllers with the test server's MVC setup.

FAIL if nothing adds the package's controllers to the test server, if the tests call the
controller class directly instead of going through HTTP, or if no tests were written.
