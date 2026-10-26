---
type: llm
focus: {source: file, path: docs/plans/topic-subscriptions/BRIEF.md}
---
PASS if every guess in BRIEF.md sits in one numbered list near the
top (in a `> [!IMPORTANT]` callout, after at most a short problem statement), each with what
changes if it's wrong. Also PASS if the brief makes no guesses. Judge only BRIEF.md itself.

FAIL if a guess sits inside a later section (for example a `> ASSUMPTION:` line under
"Problem"), or the list comes after the brief's other sections.
