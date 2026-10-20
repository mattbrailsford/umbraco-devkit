---
type: llm
weight: 2
focus: trace
---
Context: it would be an easy, wrong shortcut to read "no new backoffice screen" as "no mockup
needed for this feature at all," and skip the email because the usual screen-mockup trigger
(a changed "Frontend components" section) doesn't fire here.

PASS if the final reply does not treat the absence of a backoffice screen as a reason to skip
mocking up the email — either the email mockup exists (see the other grader), or, if it
genuinely couldn't be finished, the reply says so explicitly and does not suggest
`feature-plan` or otherwise present the design as complete.

FAIL if the reply hands off as done (e.g. suggests `feature-plan`) with no email mockup and
no mention that one is missing.
