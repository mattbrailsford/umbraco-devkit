---
type: llm
weight: 3
focus: {source: file, path: docs/plans/shared-issues-tree/mockups/tree-shared.html}
---
Context: this is a backoffice mockup in HTML. You can't render it, so judge from the markup.
Umbraco 17 shows an item's state in a tree as an entity sign: a small icon overlapping the
corner of the item's own icon, with the item's label and row height unchanged. In these
mockups it's drawn by wrapping the tree item's icon in an element with class `entity-sign`
that holds the item icon plus a second, small `uui-icon` (class `sign`), or by an equivalent
small icon positioned over the corner of the item's icon.

PASS if the shared issues keep their normal item icon and the shared state is a small icon
overlapping that icon, as above.

FAIL if the shared state is shown any other way: the item's icon swapped for a different one,
a second icon placed beside the icon or after the name, a tag, badge, count or text after the
name, a second line of text under the name, a different colour or weight on the name, or a
separate group or heading for shared issues. Also FAIL if the file is missing or an empty
placeholder, or if shared issues aren't marked at all. Say what you found.
