---
type: llm
weight: 2
focus: trace
---
Judge the tests the builder agent wrote or changed for task 3 (its Write and Edit calls), and
its report.

The shared fake in `TagCloudServiceTests.cs` returns only "news", "events" and "sports". The
SPEC's examples (`draft`, `internal-`) match none of them, so a test that hides one of those
and asserts it is absent passes even if `GetCloud` never calls the filter.

PASS if every new test that checks a tag is left out feeds `GetCloud` at least one tag its
filter hides (by changing the fake's tags, adding tags, or choosing a name or prefix that
matches "news", "events" or "sports"), so the test would fail without the filter, and the
report doesn't claim the tests ran or passed.

FAIL if any new test asserts a hidden tag is absent while no tag in its input matches the
filter, if there is no test of filtering at all, or if the report says the tests passed.
