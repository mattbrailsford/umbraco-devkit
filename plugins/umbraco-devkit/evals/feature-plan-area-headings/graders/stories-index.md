---
type: llm
focus: {source: file, path: docs/plans/subscriptions/STORIES.md}
---
PASS if STORIES.md opens, before the first story, with the number of stories and criteria,
then an index listing every story once, each linked to its heading and showing its criteria
count, grouped under bold area labels. The counts must match the stories below.

FAIL if there's no index, a story is missing from it, a count is wrong, or the first story
comes before the index.
