---
type: llm
focus: {source: file, path: docs/upgrades/v18.md}
---
PASS if the file's task list includes a task to update the package's docs pages (on its own,
or named explicitly inside another task), ordered after the code tasks that change what the
docs describe.

FAIL if no task covers updating the docs pages.
