---
type: llm
weight: 2
focus: {source: file, path: src/MyShop/Orders/OrderEmailBuilder.cs}
---
PASS if this file now skips or guards guest orders (no Customer) and, at that guard, has a
code comment that marks it as a stopgap or temporary workaround with a searchable tag (such
as `TODO(stopgap):` or another TODO-style tag), and the comment says what it hides (guest
orders get skipped or get no confirmation email) and what the proper fix is (storing guest
buyer details on Order). The comment must not link to an issue, plan, or file path.

FAIL if the guard has no comment, the comment only says what the code does, or it has no
searchable tag. FAIL if the file is unchanged.
