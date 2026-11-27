---
type: llm
---
PASS if the one question that asks to commit the plan folder and cut the branch also asks
whether to push the branch and open a draft PR once it's cut.

FAIL if the draft PR isn't mentioned, if it's asked as a separate later question, or if the
reply says it pushed or opened a PR before the user answered.
