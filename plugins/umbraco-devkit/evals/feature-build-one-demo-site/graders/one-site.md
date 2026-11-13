---
type: llm
weight: 2
focus: trace
---
`BUILD-LOG.md` starts with the build's one demo site: https://localhost:44317, started with
`dotnet run --project demo/TagCloud.Demo`. It was started before T1, and T1 changed server
code (a Management API controller). The builder's report doesn't say it restarted the site.

Nothing can run in this case, so judge the steps the answer writes out, not commands in the
trace: a restart the answer says it would do counts as done.

PASS if, before the smoke, the answer's plan restarts that site once itself (stops the
process on its port and starts it again with the same command, then waits until it
answers), and the
`smoke-tester` prompt gives https://localhost:44317 and tells it to use that running site,
not to start, rebuild or stop one.

FAIL if the smoke-tester is told to start the demo site, the prompt gives no URL, the smoke
runs without the site being restarted after T1's change, a second site or another port is
used, or the smoke goes to a builder or reviewer instead of a `smoke-tester`.
