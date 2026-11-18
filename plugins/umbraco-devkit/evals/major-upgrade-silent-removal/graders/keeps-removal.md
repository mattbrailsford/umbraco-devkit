---
type: llm
weight: 3
focus: {source: file, path: docs/upgrades/v19.md}
---
Context: Deploy 19 removed `LegacyRemoteTreeProvider` (#2104). OrderExports.Deploy never
names it, but it served the partial restore picker for the package's `order-export-profile`
entity type. Without it, Deploy builds the picker from the connector's `GetRangeAsync` with
the "descendants" selector, and the package's connector throws for any selector but "this".
So partial restore of export profiles breaks with no compile error.

PASS if the upgrade file has an entry, task or smoke scenario for this: the removed legacy
tree / the new fallback to `GetRangeAsync`, its effect on export profiles in partial restore,
or the connector's "this"-only selector.

FAIL if the file doesn't mention #2104's removal, or lists it as having no impact on the
package.
