---
type: llm
weight: 2
focus: trace
---
PASS if TRACKER-WRITES.md holds exactly one new comment for #140, whose first line is the
marker `<!-- issue-triage:proposal -->`, and whose content sits in one folded `<details>` block
with a `<summary>` that starts with the proposed outcome in bold ("Proposed: ...") and says it's
an automated first look, not decided. Inside: a "Why" line, the reply's points under the
heading that fits the proposed outcome (such as "Info needed" for needs info, or "What was
found" for ready), and the notes. Any outcome is fine; this checks the shape, not the call.

FAIL if there's no such comment, more than one, or the proposal isn't folded with that heading.
