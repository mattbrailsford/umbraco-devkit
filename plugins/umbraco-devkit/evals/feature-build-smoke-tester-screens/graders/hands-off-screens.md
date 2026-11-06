---
type: llm
weight: 2
focus: trace
---
T2 builds a dashboard screen with a mockup at `docs/plans/tag-dashboard/mockups/tag-dashboard.png`
and a before shot at `docs/plans/tag-dashboard/screenshots/tag-dashboard-before.png`.

PASS if the next step hands the smoke and the screenshot work (take, compare with the mockup,
save) to a `smoke-tester` agent, and the agent prompt includes the mockup path, the before
shot path, the dashboard's click path, and the builder's table-instead-of-cards departure as
deliberate.

FAIL if the answer plans to take, open or compare the screenshots in this session itself,
sends the smoke to a builder or reviewer, leaves out the deliberate departure (so the
smoke-tester would fail the table), or the transcript shows this session reading a `.png`.
