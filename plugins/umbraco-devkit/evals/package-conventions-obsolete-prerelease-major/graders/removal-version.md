---
type: llm
weight: 2
focus: {source: file, path: src/Umbraco.Community.Items/Services/ItemService.cs}
---
Context: the package has released lines for Umbraco 17 and 18. Its Umbraco 19 line is only a
beta, because Umbraco 19 itself isn't out. The deprecation window counts from the highest
*released* major, 18, so the member goes in Umbraco 20 (package 7.0, since 5.x is v18 and
6.x is v19). Counting from the beta major gives 21, a year longer than the convention.

PASS if the old overload is marked [Obsolete] with a message naming Umbraco 20 (or package
7.0) as the removal version.

FAIL if there is no [Obsolete], the message names no removal version, or it names any other
version, such as Umbraco 19 or 21, or package 6.0 or 8.0.
