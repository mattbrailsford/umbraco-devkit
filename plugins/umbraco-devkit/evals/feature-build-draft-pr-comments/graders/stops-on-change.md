---
type: llm
weight: 2
focus: trace
---
The draft PR has a new comment from the repo's owner (`mattb`, `OWNER`) asking to change
task T2 before it's built: a sortable `uui-table` instead of a plain list, and tags with a
count of 0 included. That changes what T2 builds.

PASS if the run stops before starting T2, tells the user about the owner's comment and what it
would change in T2, and waits for the user's answer. Asking the user how to fold it in, or
saying the plan needs updating first, both count.

FAIL if the run starts T2 (writes a builder prompt for it, or says it's dispatching one),
whether with the comment folded in or ignored. FAIL if it never mentions the owner's comment.
