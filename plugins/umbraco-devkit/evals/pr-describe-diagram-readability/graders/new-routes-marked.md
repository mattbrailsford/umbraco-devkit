---
type: llm
focus: {source: file, path: docs/plans/tag-pinning/PR-DESCRIPTION.md}
---
The branch adds two Management API routes (pin and unpin) to a controller that already had two
GET routes.

PASS if the description lists the new routes in a rendered markdown table (not inside a code
block), and a reader can tell which routes are new: a Change column or label marking them, or
a table that holds only the new routes and says so.

FAIL if the routes aren't listed, appear only inside a code block, or sit next to the existing
GET routes with nothing saying which are new.
