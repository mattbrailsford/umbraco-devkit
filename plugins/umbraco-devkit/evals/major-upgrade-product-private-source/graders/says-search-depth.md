---
type: llm
weight: 1
focus: {source: file, path: docs/upgrades/v19.md}
---
PASS if the upgrade file says which sources for Deploy's changes couldn't be read or are
still to check, such as the private source repo, the missing release notes, or a compare of
the old and new Deploy assemblies' public API still to run.

FAIL if it presents its list of Deploy changes as complete without saying what wasn't read.
