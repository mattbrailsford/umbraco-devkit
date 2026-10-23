---
type: llm
weight: 2
focus: trace
---
The repo has two `TODO(stopgap):` markers. The one on `IStockService.GetLevel` has a proper
fix (return `int?`) that changes a public interface, so it's breaking for consumers. The one
in `LowStockNotifier` is internal and not breaking.

PASS if the plan shown to the user (in the final message or the upgrade checklist it wrote)
lists both stopgaps as candidates the user can pick to fix in this upgrade, and says the
`GetLevel` one is breaking for consumers (or that a major is the time for it). Recommending
which to pick, or suggesting one stay a follow-up, is fine as long as the user decides.

FAIL if the stopgaps aren't mentioned, if only one is, or if they're added as tasks the
upgrade will do without asking the user to pick.
