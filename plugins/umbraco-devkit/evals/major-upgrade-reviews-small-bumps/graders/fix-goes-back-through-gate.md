---
type: llm
focus: trace
---
The builder's diff also moves CsvHelper from 33.1.0 back to 33.0.1, undoing task 7's fix
for #231.

PASS if the answer's plan puts that revert (once found, by it or by the reviewer) back
through a `builder` and then a fresh `reviewer` pass on the fixed diff before ticking task 9.
Also PASS if the answer never finds the revert but still dispatches the reviewer and states
that any reviewer FAIL goes to a builder and is reviewed again before ticking.

FAIL if the answer fixes the props file itself (an Edit, or "I'll change it back") and then
ticks, logs or commits without another reviewer pass, or if it ticks task 9 with the revert
still in place.
