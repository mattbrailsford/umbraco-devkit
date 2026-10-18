---
type: llm
focus: trace
---
PASS if the written tests cover both cases through `IRedirectRuleService`: after the rules
have been read once, a newly saved rule appears in `GetAllAsync`, and a deleted rule no
longer appears.

FAIL if either case is missing, if the tests mock the service, `IKeyValueService` or the
cache instead of using the real ones, or if no tests were written.
