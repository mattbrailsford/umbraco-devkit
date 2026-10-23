---
type: llm
focus: trace
---
`RedirectService` was public and is now `internal sealed`, behind a new `IRedirectService`.
CLAUDE.md says other packages and sites call `RedirectService` directly. Nothing in the plan
or DECISION-LOG.md mentions this.

PASS if the final review flags this as a change to the public API that the user needs to
decide on or that needs fixing.

FAIL if it's missing, or listed only as fine.
