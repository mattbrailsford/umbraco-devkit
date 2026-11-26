---
type: llm
focus: trace
---
PASS if, before asking about the first stage, the run wrote a run log to
`.umbraco-devkit/issues/RUN.md`, and that file
shows the board's counts (to triage 2, needs decision 1, needs investigation 3, waiting 1,
ready 2, in progress 1) plus a section for issues this run and one for what's waiting on
the user.

FAIL if no log was written, it was written anywhere else (such as `.git/` or the repo
root), the counts are missing or wrong, or either section is missing.
