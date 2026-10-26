---
type: llm
focus: {source: file, path: docs/how-delivery-works.md}
---
PASS if the page shows the delivery states and the moves between them (Pending, Sending,
Delivered, Failed, Retrying, Dead) in a diagram, and the text doesn't also walk through the
same moves step by step. Text that adds what the diagram can't show (timings, limits, the
backoff formula, load-balancing, cleanup) is fine.

FAIL if there's no diagram of the states, or the text repeats the state-by-state walkthrough
the diagram already shows.
