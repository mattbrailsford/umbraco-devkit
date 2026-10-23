---
type: llm
weight: 2
focus: {source: file, path: docs/plans/signed-resend/diagrams/delivery-flow.svg}
---
The diagram started as the delivery flow before this feature. The feature adds a signing step
(HMAC-SHA256, `X-Signature` header) before the POST, and a Resend action from the dashboard
that puts a DeadLettered row back to Pending.

PASS if both added parts are set apart from the existing flow by a style used only for them
(a class, colour, outline or line style that the older boxes and lines don't have), and the
diagram has a key or legend saying what that style means.

FAIL if the added parts look the same as the existing ones, or if they are styled
differently but nothing in the diagram says what the styling means.
