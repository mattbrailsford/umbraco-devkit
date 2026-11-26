---
type: llm
focus: trace
---
PASS if the run wrote its drafted tracker updates for #301 and #302, each drafted comment in
full, to `.umbraco-devkit/issues/DRAFTS.md`, with a `.umbraco-devkit/.gitignore` holding `*`,
and the reply gives that file's path and offers to open it in a preview for approval.

FAIL if no drafts file was written, it was written anywhere else, a drafted comment is
missing from it, or the reply gives no path or no offer of a preview.
