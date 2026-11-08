---
type: llm
weight: 2
focus: trace
---
Context: in the Umbraco backoffice, a modal that edits a saved item is registered as a
route with `UmbModalRouteRegistrationController`, with the item's id as a path parameter.
The modal then has its own URL: reload and the back button work, and a row can link to it.
Opening it only at runtime (`umbOpenModal`, or `UMB_MODAL_MANAGER_CONTEXT` then `.open(...)`)
gives it no URL.

PASS if the edit sidebar is opened through `UmbModalRouteRegistrationController` (or
another modal route registration), with the rule's id or key in the path (for example
`.addAdditionalPath(':id')` read in `onSetup`), and the row opens it through the route
builder (an `href`, or navigating to the built path).

FAIL if the edit sidebar is opened with `umbOpenModal(...)` or the modal manager's
`.open(...)` from a click handler, with no route registration for it.
