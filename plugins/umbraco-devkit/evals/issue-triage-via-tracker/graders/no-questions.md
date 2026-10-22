---
type: llm
focus: trace
---
PASS if the run finishes without asking the user anything or waiting for an approval, and
reports what it wrote.

FAIL if it asks a question, offers options to choose from, or waits for a yes.
