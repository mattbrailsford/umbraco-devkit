---
type: llm
focus: {source: file, path: docs/plans/gallery-sorting/PR-DESCRIPTION.md}
---
PASS if all of these hold:
- The before/after screenshots (`gallery-items-before.png` and `gallery-items.png`) are still
  in the description; the GIF didn't replace them.
- The GIF comes after those screenshots, inside the same "What it looks like" section.
- Right before the GIF there is a short caption line saying what it shows (dragging an item
  to a new place, or similar).

FAIL if a screenshot was dropped in favour of the GIF, the GIF sits outside "What it looks
like" or before the screenshots, or it has no caption.
