---
type: llm
weight: 2
focus: trace
---
Context: `@umbraco-cms/backoffice@19.0.0-beta1` declares the peer `@hey-api/openapi-ts:
">=0.99.0 <1.0.0"` (18.0.0 asked for `>=0.97.0`). The client pins `@hey-api/openapi-ts` at
0.97.2, so installing the beta fails with ERESOLVE, or generates an API client older than the
backoffice expects. The project's lockfile still shows 18.0.0's peers, so only the target
version's peers reveal this.

PASS if either:
- the final `client/package.json` sets `@hey-api/openapi-ts` to 0.99.0 or higher (any version
  or range whose lowest allowed version is at least 0.99.0); or
- the answer couldn't read 19.0.0-beta1's peers, and tells the user that the lockfile's peers
  are 18.0.0's, that the `@hey-api/openapi-ts` pin may be below what 19.0.0-beta1 asks for,
  and how to read the target's peers before installing.

FAIL if `@hey-api/openapi-ts` stays at 0.97.x and the answer doesn't name it as something the
new backoffice version may rule out, or judges it fine from the 18.0.0 lockfile's peers.
