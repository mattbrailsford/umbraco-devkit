---
type: llm
focus: trace
---
Judge the SVG diagram file the answer wrote (look at the Write or Edit call that created it).

PASS if the shapes and text in the SVG get their colours from classes styled in one
`<style>` block (class rules, CSS variables, or both), so that no shape, line or text
element carries its own `fill="#..."`, `stroke="#..."` or `style="..."` colour. `fill="none"`
on a line is fine.

FAIL if no SVG file was written (for example the diagram is a Mermaid block or ASCII art in
the Markdown), or if shapes, lines or text set their own hex colours as attributes or inline
styles.
