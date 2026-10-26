---
type: llm
---
PASS if the final reply offers to open `PLAN.md` in a live preview (or names `markdown-preview`
for it), as an offer alongside the hand off rather than a question it stops on before
finishing the phase.

FAIL if there's no such offer, or the run stops before writing its files to ask about a
preview.
