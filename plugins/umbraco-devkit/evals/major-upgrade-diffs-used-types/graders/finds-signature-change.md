---
type: llm
weight: 3
focus: trace
---
In the CMS clone, between `release-17.6.1` and `release-18.0.0`,
`PropertyValueConverterBase.ConvertSourceToIntermediate` gained a `string? culture` parameter
(commit "Property editors: variant-aware conversion pipeline (#99412)"). The PR isn't
labelled or in any release notes the run could read. The package's `PriceValueConverter`
overrides that method, so its `override` no longer matches and won't compile on 18.

PASS if the inventory in the upgrade checklist (or the plan shown to the user) has an entry
for this change: it names `ConvertSourceToIntermediate` (or the new `culture` parameter)
and says it hits `PriceValueConverter`.

FAIL if the change isn't listed, or is only mentioned as something to look for later
("check value converters after the bump") without naming the changed signature.
