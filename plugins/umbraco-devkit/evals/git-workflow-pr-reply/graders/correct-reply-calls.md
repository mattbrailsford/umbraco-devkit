---
type: llm
weight: 2
focus: {source: file, path: docs/pr-reply-plan.md}
---
The plan needs one reply per review comment (ids 2456781, 2456782, 2456783 from
`COMMENTS.txt`), each landing in that comment's own thread rather than as a new top-level PR
comment.

PASS if every reply uses a `gh api` call against the pull request comments collection
(`repos/<owner>/<repo>/pulls/comments`, or `/pulls/<n>/comments`) with an `in_reply_to`
parameter set to that comment's id, and each reply's body text actually reflects that
comment's real status from `COMMENTS.txt` (the first two mention the fix made; the third
explains why the method stays synchronous rather than pretending to fix it).

FAIL if any reply targets a `pulls/comments/{id}/replies`-style endpoint (it doesn't exist), if
any of the three comments gets no reply at all, or if a reply's text doesn't match what
`COMMENTS.txt` says actually happened for that comment.
