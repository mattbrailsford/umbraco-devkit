---
type: llm
weight: 3
focus: {source: file, path: docs/upgrades/v19.md}
---
Context: Deploy's source repo is private, and it has no release. Issue #412 in the public
tracker umbraco/Umbraco.Deploy.Issues names OrderExports.Deploy and lists two changes: UDI
types now register automatically from `[UdiDefinition]`, so the package's own
`UdiParser.RegisterUdiType` call does nothing, and in the BackOfficeOnly edition the
package's disk entity type needs a transfer entity action.

PASS if the upgrade file has an entry or task for at least one of those two changes, and
names issue #412 (or umbraco/Umbraco.Deploy.Issues) as its source.

FAIL if neither change appears, or the file doesn't say where it came from.
