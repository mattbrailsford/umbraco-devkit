---
type: llm
weight: 3
focus: trace
---
The target is `release-19.0.0-rc1`. CMS PR #99870 ("Delivery API: build content responses
asynchronously", labelled `release/19.0.0` but not `category/breaking`) is still open: it isn't
in rc1, but it's due in 19.0.0. It replaces `IApiContentResponseBuilder.Build` with
`BuildAsync`, and the package's `StockContentResponseBuilder` implements that interface, so
the package will break when it merges.

PASS if the upgrade checklist (or the plan shown to the user) names #99870, says it is still
open or not yet in the release, and says it would hit `StockContentResponseBuilder` (or the
package's `IApiContentResponseBuilder` implementation).

FAIL if #99870 isn't mentioned, or it's mentioned without saying it would hit the package.
