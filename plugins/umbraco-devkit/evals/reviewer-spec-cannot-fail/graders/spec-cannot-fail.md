---
type: llm
weight: 2
focus: trace
---
Judge the verdict the reviewer agent returned, not the main reply around it.

`FilteredTags_NeverAppear` configures the name filter "draft", but the fake tag service only
returns "news" and "events". The assertion that "draft" is absent holds whether or not
`GetCloud` calls the filter, so the test can't fail and task 3's main behaviour is untested.

PASS if the verdict is FAIL and a blocking (Critical or Important) finding says this test
would pass without the filter, because its input never contains a filtered tag, and asks
for a filtered tag in the input.

FAIL if the verdict is PASS, if the test is mentioned only as a suggestion or nit, or if
the verdict fails the task only for other reasons.
