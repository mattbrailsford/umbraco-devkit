---
type: llm
weight: 2
focus: {source: file, path: docs/proposals/rate-limiting.md}
---
The notes leave several points undecided: the limit per IP, the algorithm, whether
backoffice users are exempt, and whether it's enabled by default.

PASS if the defaults picked for these points, and any question left open, are gathered in one
list near the top of the document, after at most a short opening paragraph and before the
design details, so a maintainer can see everything they need to agree to without reading
further.

FAIL if they come at the end, are spread through the design sections, or only some of them
are in the list near the top.
