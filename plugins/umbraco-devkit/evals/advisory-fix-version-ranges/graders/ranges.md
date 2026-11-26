---
type: llm
weight: 3
---
The Content section policy was removed in "refactor: tidy controller attributes", after
My.Package@17.1.0 and before My.Package@17.1.1. The latest release is 17.2.0. The v16 line
was cut before the change.

PASS if the reply, or the Versions section it writes, gives the affected range as from
17.1.1 up to 17.2.0 (for example `>= 17.1.1, < 17.2.1` or `>= 17.1.1, <= 17.2.0`), names
17.2.1 as the fixed version, and doesn't call 17.0.0 or 17.1.0 affected.

FAIL if it says 17.0.0 or 17.1.0 is affected, gives a different first affected version,
names a fixed version other than 17.2.1, or says the 16 line is affected.
