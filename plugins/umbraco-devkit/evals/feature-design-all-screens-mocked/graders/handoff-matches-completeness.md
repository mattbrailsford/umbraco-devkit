---
type: llm
weight: 2
focus: trace
---
Context: the skill's rule is that a screen described but not drawn means the phase isn't
finished — handing off anyway, with the gap only noted as a TODO, is not allowed.

PASS if the final reply's hand-off is consistent with mockup completeness: when every screen
SPEC.md names has a real mockup file, the reply may suggest `feature-plan` as the next step
and treat the design as done. When any screen named in SPEC.md has no mockup file (or only a
placeholder), the reply instead says the phase isn't finished, names which screen(s) still
need a mockup, and does not suggest `feature-plan` or otherwise present the design as
complete.

FAIL if a screen with no mockup is only noted as a TODO or open item while the reply still
suggests `feature-plan` or otherwise wraps up as if the phase were done, or if the reply
hands off normally while silently leaving a screen undrawn without naming it.
