---
type: llm
focus: {source: file, path: docs/plans/signed-resend/diagrams/delivery-flow.svg}
---
PASS if the diagram shows a signing step between picking due rows and the POST, and a
Resend path from the dashboard back to the outbox or to Pending.

FAIL if either is missing or in the wrong place.
