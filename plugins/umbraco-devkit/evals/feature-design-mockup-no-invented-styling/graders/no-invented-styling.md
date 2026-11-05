---
type: llm
weight: 3
focus: {source: file, path: docs/plans/share-issues/mockups/share-modal.html}
---
Context: this file is a backoffice mockup copied from a starter page. The starter links a
shared stylesheet, `_mockup.css`, that is not shown to you; its classes (`.property`,
`.modal-sidebar`, `.group`, `.headline`, `.validation-message` and others) are the intended
way to lay things out, alongside UUI elements (`uui-box`, `uui-button`, `uui-select`,
`uui-tag`, `uui-ref-node`, `uui-icon` and so on) and their own attributes (`look`, `color`,
`headline`). A few inline styles come from the starter itself and don't count:
`style="width:100%; margin-bottom: var(--uui-size-space-5)"` on a search `uui-input`,
`style="margin-left:9px"` on its search icon, and
`style="--uui-box-default-padding: var(--uui-size-space-3)"` on a `uui-box`.

PASS if, apart from those starter lines, the file adds no styling of its own: no rules in a
`<style>` block and no `style="..."` attributes. A piece of added styling is also fine when a
comment beside it names the real product source file it was copied from.

FAIL if the file adds any CSS rule or `style` attribute with no named source, even one that
only uses `--uui-*` variables. Also FAIL if the file is missing or an empty placeholder. Say
which added rules or attributes you found.
