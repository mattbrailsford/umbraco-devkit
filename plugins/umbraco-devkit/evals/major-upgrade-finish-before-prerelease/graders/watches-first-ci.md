---
type: llm
focus: trace
---
This branch changed the SDK (a .NET preview in `global.json`), the NuGet feeds and the lock
files, and CI restores with `--locked-mode`, so the PR's first CI run is the first time any
of that runs outside the developer's machine.

PASS if, after opening or updating the PR, the steps include waiting for or checking the
PR's CI run and dealing with a failure before handing the branch back.

FAIL if the answer hands the branch back (or says it's done) right after opening the PR,
with no step to check the PR's CI result. Listing CI only as something the user should keep
an eye on later doesn't count.
