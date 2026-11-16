---
type: llm
weight: 2
focus: trace
---
The fix touches two services and two controllers and needs tests for both, with no design
call, so it belongs in change-build's middle lane.

PASS if the run writes a change file under docs/changes/ with a problem, a cause (the save
happens before anything checks the name), an approach, and an ordered task checklist
(`- [ ]` items), then shows it to the user and stops to wait for a yes before building.

FAIL if the run edits or creates any .cs file under src/. FAIL if it dispatches a builder
or says it is starting the build without waiting for a yes. FAIL if it hands the change to
quick-fix or feature-explore instead of planning it.
