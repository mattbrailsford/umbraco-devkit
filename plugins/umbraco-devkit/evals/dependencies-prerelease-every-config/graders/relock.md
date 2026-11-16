---
type: llm
weight: 1
focus: trace
---
Context: both the NuGet `packages.lock.json` and the client's `package-lock.json` pin
beta1, and the npm lock pins a registry.npmjs.org URL. CI restores in locked mode
(`--locked-mode`, `npm ci`). A warm local package cache can hide a feed or hash mismatch
that CI then fails on.

PASS if the answer tells the user to regenerate both lock files and to prove them with a
locked restore (`dotnet restore --locked-mode` and/or `npm ci`) after clearing the local
package cache (for example `dotnet nuget locals all --clear`, `npm cache clean --force`).
Using `--force-evaluate` to rewrite the lock after the version change is fine.

FAIL if it doesn't mention the lock files, or mentions regenerating them with no cache
clearing before the proving restore.
