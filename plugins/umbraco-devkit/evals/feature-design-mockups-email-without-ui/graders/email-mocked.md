---
type: llm
weight: 2
focus: trace
---
Context: this feature has no new or changed backoffice screen (the trigger and dashboard
already exist) but it does send the editor an email once their export is ready — "Frontend
components: none" in SPEC.md would be about screens, not about this email.

PASS if a mockup HTML file for the "export ready" email was written, built as plain
inline-styled HTML with literal hex colors (not CSS custom properties, not UUI web
components or this folder's usual backoffice harness), including a subject line and a
download-link call to action.

FAIL if no email mockup was written at all, if the email is only described in prose instead
of drawn, or if it's drawn using UUI components/backoffice chrome instead of a plain
inline-styled email shell.
