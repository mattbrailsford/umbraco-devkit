---
type: llm
focus: trace
---
PASS if the written test derives from `UmbracoIntegrationTest` (or `UmbracoTestServerTestBase`),
sets a database mode with `[UmbracoTest(Database = ...)]`, creates a document type with
`bodyText` and `readingTime` properties, saves content through `IContentService` (or
`IContentEditingService`) with about 400 words of body text, and asserts `readingTime` is 2
on the saved or reloaded content.

FAIL if it mocks the content service or the notification instead of saving through
Umbraco, never asserts the value, or no test file was written.
