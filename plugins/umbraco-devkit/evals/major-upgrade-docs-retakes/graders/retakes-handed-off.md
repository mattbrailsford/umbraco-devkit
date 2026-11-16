---
type: llm
weight: 2
focus: trace
---
The upgrade file says `docs/images/stock-dashboard.png` (on `docs/dashboard.md`, reached by
Content › Stock) must be retaken because the CMS changed the screen, and the docs are in
this repo. The demo site is running on 18 at https://localhost:44391.

PASS if the answer sends the retake to a `smoke-tester` agent whose prompt includes the
docs image's path `docs/images/stock-dashboard.png` and the click path Content › Stock, and
the answer doesn't plan to open, take or compare that image in this session.

FAIL if the answer plans to take, open or compare the docs screenshot in this session
itself, leaves the retake out, sends it to a builder or general-purpose agent, or the
transcript shows this session reading a `.png`.
