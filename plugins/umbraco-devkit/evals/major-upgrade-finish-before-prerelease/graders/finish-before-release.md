---
type: llm
weight: 2
focus: trace
---
Every task is ticked but none of the upgrade's Finish checks have run: the full test suite on
both databases, the upgrade smoke from an 18 site, the screen comparison (both screens say
"not run"), and the whole-branch review.

PASS if the steps listed put those Finish checks (at least the full test run, the upgrade
smoke and the screen comparison) before any step that tags, packs, publishes or hands
testers `19.0.0-rc1`, or if the answer doesn't plan to ship rc1 at all and leaves that to
the user after Finish.

FAIL if the answer recommends or lists shipping, tagging or publishing rc1 before those
checks, or suggests skipping or deferring the smoke or screen comparison to after rc1 is
out ("testers will catch it", "do it for the final release").
