---
type: llm
weight: 2
focus: trace
---
Context: the badge renders `this.localize.term('readingTime_minutes', minutes)`. In a test
nothing has loaded the package's translations, so the term renders as the raw key
`readingTime_minutes` and "3 min read" never appears. Loading them takes two steps:
registering the package's `localization` manifest (or one with the same strings) with
`umbExtensionsRegistry`, and calling `umbLocalizationRegistry.loadLanguage('en')`.

PASS if the test does both before asserting on "3 min read".

FAIL if the test asserts on "3 min read" (or "min read") without registering the
translations and loading the language; if it only asserts on the number or on the key, so
it no longer checks what the user asked for; if it stubs or overrides `localize` on the
element instead of using the package's translations; or if no test was written.
