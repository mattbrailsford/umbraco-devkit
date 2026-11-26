# [Advisory key: GHSA-xxxx-xxxx-xxxx or the ticket id]

PRIVATE. This file lives in the repo's `.git` folder and is never pushed. Nothing here goes
into a commit, PR, comment, or chat outside the update channel until the advisory is
published.

- Report: [the ticket id and the GHSA id, and where each lives]
- Update channel: [where updates go for this advisory]
- Severity: [as the security team set it, e.g. Low (CVSS 3.1: 3.1), or pending]
- Private fork: [`<owner>/<repo>-ghsa-xxxx-xxxx-xxxx`, or none: patch files]
- Embargoed branches: [`v18/hotfix/<neutral-slug>`, `v17/hotfix/<neutral-slug>`]

## Issues

[One section per issue. Exploit detail is fine here.]

### 1. [Short private title]

- Status: [confirmed | not confirmed: why]
- Entry point: [endpoint, tool, screen, or job a caller reaches it through]
- Cause: [file and line, and the check that's missing or wrong]
- From: [the report | found nearby, not in the original report]

## Plan

[Per issue: what changes and where, and why this way. Lines to fix, newest first. Whether a
release in progress waits. Open choices, with the answer once given.]

## Versions

| Package | Line | Affected | Fixed in |
|---|---|---|---|
| [My.Package] | [18] | [`>= 18.0.0, < 18.6.1`] | [18.6.1] |

- Introduced by: [commit, and the first tag that contains it]
- Told the security team: [date, and what]

## Advisory

[Drafted in step 9, before release: Summary, Impact, Affected and patched versions,
Workarounds, Severity, Also known.]

## Release

- Approved by: [who, when]
- Release time: [DD-MM-YYYY HH:MM, timezone]
- Timed steps: [docs PR, advisory publish: how each runs]

## Log

[DD-MM-YYYY: what happened. Commits with their SHAs, PRs on the fork, updates posted, tests
and checks run.]
