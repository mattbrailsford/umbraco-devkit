---
type: llm
weight: 2
focus: trace
---
PASS if the run tells the two incidents apart:
- The `GetTotal` → `GetTotalAsync` rename with no `[Obsolete]` proxy is treated as a mistake a
  devkit skill should have caught, and routed toward `skill-report` (named, or described as
  "report this to the devkit") rather than saved as a plain project `gotcha`.
- The `DOTNET_ENVIRONMENT=Test` test setup is treated as this project's own trap, to be saved
  to `.claude/memory/` as a `gotcha`, not sent to `skill-report`.

FAIL if both incidents are routed the same way (both to skill-report, or both saved as a
gotcha with no distinction), if the rename incident is saved as a gotcha instead of routed to
skill-report, if the test-setup incident is sent to skill-report, or if a new `.claude/memory/`
entry type is invented for either instead of using `gotcha`.
