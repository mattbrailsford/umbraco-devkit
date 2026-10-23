---
type: llm
weight: 2
focus: {source: file, path: docs/plans/tag-pinning/PR-DESCRIPTION.md}
---
Look at every `diff` code block in the file. `TagCloudService.cs`, `TagCloudController.cs` and
`TagCloudItem.cs` already existed and were changed, not deleted.

PASS if no `diff` block shows a `-` line for something that still exists (a file, a call, a
step) followed by a `+` line for that same thing with only a note, comment or label added. A
changed file or step shown as an unmarked context line with a note is fine. A real line change
(code that differs, such as a record's parameter list growing) shown as `-` then `+` is fine.

FAIL if any `diff` block removes a line and adds the same item back just to annotate it, for
example `-└── TagCloudService.cs` then `+└── TagCloudService.cs  # now puts pins first`.
