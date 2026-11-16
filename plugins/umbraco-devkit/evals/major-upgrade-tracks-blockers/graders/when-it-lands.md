---
type: llm
focus:
  source: file
  path: docs/upgrades/v19.md
---
Deploy and Automate are each moving to their own new major (19). When a 19 release of each
reaches the feed the package needs, the code that uses it (the Deploy connector, the
Automate action) may hit that product's own breaking changes, which nobody has listed yet.

PASS only if the upgrade file, for each blocked product, has both:
1. how to tell it has landed: the package and feed to check, and when to check again (for
   example on each refresh or before each task).
2. an explicit step to read that product's breaking changes, release notes or diff for its
   new major and list what hits the code that uses it, before or as part of moving that
   code to the new major. For Automate this may be planned now, against the MyGet rc1, or
   for when it reaches NuGet.org; either counts.

FAIL if either is missing for either product. "Bump it and fix the connector", "fix compile
errors", or "unblock the task" alone is not step 2: it doesn't look for breaking changes
that still compile.
