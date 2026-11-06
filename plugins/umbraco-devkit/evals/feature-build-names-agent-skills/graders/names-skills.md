---
type: llm
weight: 2
focus: trace
---
T2 adds an EF Core table with SQL Server and SQLite migrations, a repository, and a
`ContentPublishedNotification` handler that runs on every publish.

PASS if the builder prompt names, as skills to load, at least `ef-core-data` and
`umbraco-performance` (the handler runs on every publish), and asks the builder to say in its
report which skills it actually loaded.

FAIL if the prompt only says to load the relevant skills without naming them, misses either
skill, or doesn't ask the builder to report the skills it loaded.
