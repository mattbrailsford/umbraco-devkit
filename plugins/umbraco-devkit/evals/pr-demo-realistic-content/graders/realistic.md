---
type: llm
weight: 2
---
The demo site is a small coffee roastery's site with a blog. The branch adds a dashboard
listing posts by tag, 10 per page.

PASS if the content the reply would add looks like a real roastery blog: real-sounding post
titles (for example about brewing, origins, or a new roast), with varied lengths including at
least one long title, and enough posts under at least one tag for the dashboard's second page
to show. Posts it reuses from the existing demo content count toward that.

FAIL if titles are placeholders ("Test post 1", "Post 2", "foo", lorem ipsum), unrelated to
the site's subject, or nothing it sets up reaches a second page, or it doesn't say what
it would add.
