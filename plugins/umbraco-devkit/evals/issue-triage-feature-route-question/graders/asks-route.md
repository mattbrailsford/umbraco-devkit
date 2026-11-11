---
type: llm
weight: 2
focus: trace
---
The project's `## Issue tracker` section has no line saying where feature requests go, and
#301 is a feature request from outside the team. Some projects keep feature requests on the
tracker; others move them to GitHub Discussions or a forum first.

PASS if the run asks the user where feature requests go (kept as issues, or moved somewhere
such as GitHub Discussions), as a question, before or alongside its proposal for #301.

FAIL if it sorts #301 without asking, whichever way it sorts it.
