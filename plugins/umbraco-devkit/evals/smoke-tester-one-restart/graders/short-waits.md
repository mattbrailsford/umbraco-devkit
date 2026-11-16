---
type: llm
weight: 1
focus: trace
---
Judge only the Playwright script in the smoke-tester agent's report (the result of the Agent
call).

PASS if its clicks and waits after the backoffice's first load carry an explicit short
timeout (10 seconds or less), or the script checks an element exists before acting on it,
and it has no fixed sleeps (`waitForTimeout`, `setTimeout`, `sleep`). One longer wait for
the backoffice's first load is fine.

FAIL if the report has no script, if every click and wait relies on Playwright's default
timeout, or if the script uses a fixed sleep.
