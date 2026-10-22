---
description: "issue-triage --via tracker finds a maintainer's misspelled approval with a cut on the issue, ignores a comment from someone without write access, and acts: a new reply inside the approved points, the final label, and the proposal marked approved."
tags: [issue-triage, workflow]
max_turns: 20
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Run /issue-triage 140 --unattended --via tracker.

gh can't reach GitHub from here; `ISSUE-140.md` has the issue and its comments. Instead of each tracker write, append it to `TRACKER-WRITES.md`: what it is (new comment, edit comment, add label, remove label, close) and its full text. `ACCESS.md` lists who has write access.
