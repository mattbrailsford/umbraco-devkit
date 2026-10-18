---
type: llm
focus: trace
---
Context: `ReadingTimeContext` extends `UmbContextBase`, which needs an Umbraco controller
host. Created on a plain element (a `<div>`, a bare `HTMLElement`, or a `LitElement`), it
throws `addUmbController is not a function`.

PASS if the test provides the context from an element that is an Umbraco controller host,
for example a test element extending `UmbLitElement` (or using `UmbElementMixin`), with the
badge placed inside it so it consumes the context. Providing a fake context with
`provideContext(READING_TIME_CONTEXT, ...)` from such a host also passes.

FAIL if the context is created on a plain element (often with an `as any` cast), if the test
sets the element's private state directly instead of going through the context, or if no
test was written.
