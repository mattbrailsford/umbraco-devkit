---
type: llm
weight: 2
focus: trace
---
Context: this feature naturally needs more than one screen (at least: a place to see failed
deliveries for an issue and retry them, and somewhere a support person looks up one member's
delivery history). SPEC.md's "Frontend components" section names each screen the feature
adds.

PASS if a `mockups/<screen>.html` file was written for every screen SPEC.md names, each with
real, screen-specific markup (its own layout, labels and UUI elements) — not an empty file or
a one-line placeholder.

FAIL if any screen SPEC.md names has no mockup file at all, or if a mockup file exists but is
just a stub with no real screen content.
