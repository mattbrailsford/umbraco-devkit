---
type: llm
weight: 2
focus: {source: file, path: docs/plans/routing-rule-editor/mockups/routing-rule-form.html}
---
Context: you cannot render this HTML/CSS, and the shared `_mockup.css` file's own rules are
not shown to you, so judge only by what's actually written in this file, not by how the
markup resembles another pattern you've seen. The shared `_mockup.css` already makes a
`.property` row (used by `modal-form.html`/`editor.html`) stack automatically — label, then
description, then the editor, full width — inside any sidebar modal, via a CSS container
query keyed off the row's own rendered width. It only stays side by side (a fixed label
column next to the editor) once the modal is wide enough, which in practice means a modal
explicitly marked `class="large"`, or a full editor screen. A plain `.property` div with no
extra classes, used inside a plain `<aside class="modal-sidebar">` with no `large` class,
already gets the correct (stacked) layout for free — that is what a correct answer looks
like in this file, not a visibly different structure.

PASS if this file is a sidebar modal with no `class="large"` on its `.modal-sidebar` element
(or an explicit, stated reason in a comment for needing the wide layout), and its own
`<style>` block (if any) contains no rule that forces `.property`'s columns/grid back to
side by side (for example setting `grid-template-columns` or `grid-column` on `.property` or
its children). The ordinary `.property` div structure itself (a header div then an editor
div) is correct and expected either way — its layout comes from the shared CSS, not from
anything visible in this one file, so do not fail it just because it structurally resembles
`editor.html`.

FAIL only if you find actual evidence of a side-by-side override in this file: the modal is
marked `large` with no stated reason, or this file's own `<style>` block contains CSS that
re-widens or re-columns `.property`. Also FAIL if the file doesn't exist or is an empty/stub
placeholder.
