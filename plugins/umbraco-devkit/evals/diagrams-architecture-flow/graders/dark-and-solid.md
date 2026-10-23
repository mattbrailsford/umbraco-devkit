---
type: llm
focus: trace
---
Judge the SVG diagram file the answer wrote (look at the Write or Edit call that created it).

PASS if both hold: the SVG's styles give a second set of colours under
`@media (prefers-color-scheme: dark)`, and the SVG paints a solid background covering the
whole canvas (for example a full-size `rect` filled from the stylesheet), so it is readable
on a light or a dark page.

FAIL if no SVG file was written, if it has no dark-mode colours, or if its background is
transparent (no full-canvas background shape).
