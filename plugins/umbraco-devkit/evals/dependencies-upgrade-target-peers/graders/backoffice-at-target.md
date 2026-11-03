---
type: regex
pattern: '"@umbraco-cms/backoffice"\s*:\s*"[~^]?19\.0\.0-beta1"'
match: contains
target: {source: file, path: client/package.json}
---
