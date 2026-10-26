---
type: llm
focus: {source: file, path: docs/plans/tag-reports/STORIES.md}
---
PASS if STORIES.md opens, before the first story, with the number of stories and criteria,
then an index listing every story in the file (the existing STORY-1 and STORY-2 and the new
ones), each linked to its heading with its criteria count. The counts must match the stories
below.

FAIL if there's no index, a story is missing from it, or a count is wrong.
