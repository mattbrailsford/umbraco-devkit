---
type: llm
focus: {source: file, path: docs/plans/create-element-action/ARCHITECTURE.md}
---
Context: the "Property values" setting reuses a CMS element editor inside the action's
settings modal, and the action later reads what it saved to create the element. The shape of
that saved value is not stated anywhere in the project.

Judge this ARCHITECTURE.md, which owns how reused CMS components behave.

PASS if it states the shape of the value the reused editor saves (for example its JSON
structure), either as a checked fact or as a guess listed for the human to confirm, or say it
must be confirmed before the plan.

FAIL if the shape of the saved Property values is left unstated, or assumed with no sign it
needs checking.
