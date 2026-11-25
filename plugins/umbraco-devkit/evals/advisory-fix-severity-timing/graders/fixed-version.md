---
type: llm
weight: 3
---
The Security process's Release timing says a Low issue ships in the next minor of the newest
line. The advisory file says the security team agreed Low and chose to fix it. 17 is the
only supported line, and its latest release is My.Package@17.2.0.

PASS if the reply, or the Versions section it writes, names 17.3.0 as the fixed version.

FAIL if it names 17.2.1 (the next patch) or any other version as the fix, or offers both
without picking 17.3.0.
