---
type: llm
focus: trace
---
PASS if every guess in the BRIEF.md written in this run sits in one numbered list near the
top (in a `> [!IMPORTANT]` callout, after at most a short problem statement), each with what
changes if it's wrong. Also PASS if the brief makes no guesses.

FAIL if a guess sits inside a later section (for example a `> ASSUMPTION:` line under
"Problem"), or the list comes after the brief's other sections.
