---
type: llm
weight: 2
focus: trace
---
Context: `mockups/usage.html` is about 1,300px tall at 1440px wide. Its last section, "Other
states" (empty, error, loading and no-access tiles), sits below the first 900px.

PASS if the saved `mockups/usage.png` holds the whole page down to the "Other states" tiles:
the screenshot was taken full-page (for example Playwright's `full_page`/`fullPage`, or the
Chrome DevTools full-page capture), or the window was sized to the page's measured height,
or a first 900px-high shot was looked at, found cut off, and retaken taller.

FAIL if the only saved screenshot is a fixed 1440×900 (or other fixed-height) shot that
cuts the page off before the "Other states" tiles, or if no screenshot was saved.
