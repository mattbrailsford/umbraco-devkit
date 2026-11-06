---
type: llm
focus: trace
---
PASS if, after saving `mockups/usage.png`, the answer opened the image itself (a Read of the
PNG, or a check of its pixel height against the page's height) before showing it to the user.

FAIL if the answer showed or reported the screenshot without ever opening or measuring the
saved image.
