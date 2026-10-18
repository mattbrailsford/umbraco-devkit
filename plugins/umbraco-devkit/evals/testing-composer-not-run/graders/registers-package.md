---
type: llm
weight: 2
focus: trace
---
Context: `UmbracoIntegrationTest` builds Umbraco without calling `AddComposers()`, so the
package's `ReadingTimeComposer` never runs in the test. Nothing registers
`ReadingTimeSavingHandler`, its calculator or its settings unless the test does.

PASS if the test class (or a base class it writes) registers the package in the test's
Umbraco builder, for example by overriding `CustomTestSetup(IUmbracoBuilder builder)` and
calling `builder.AddReadingTime()`, `builder.AddComposers()`, or
`new ReadingTimeComposer().Compose(builder)`, or by registering the handler with
`AddNotificationHandler<ContentSavingNotification, ReadingTimeSavingHandler>()` together with
the calculator and settings it depends on. A `[ConfigureBuilder]` attribute that does the
same also passes.

FAIL if the test relies on the composer being discovered automatically, registers only the
handler without the services it needs, or no test file was written.
