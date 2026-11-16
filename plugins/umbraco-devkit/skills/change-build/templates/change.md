# [Short title of the change]

Branch `[fix/slug]`, cut from `[trunk]`. Source: [tracker issue #123, an idea's name, or
"asked in chat"].

## Problem

[What's wrong or missing, for whom, in their terms. Two or three lines.]

## Repro

[Bugs only. The steps or test that show the bug, through the real entry point. Delete this
section for an enhancement.]

1. [Log in to the backoffice, open Settings > My Package]
2. [Save with the Name field empty]
3. [Expected: a validation message. Actual: a 500 error.]

## Cause

[Bugs only. Where the cause lives and why, with file and line. Then other places with the
same cause, and whether this change fixes them.]

- [`src/MyPackage/Services/SettingsService.cs:42`: saves before validating]
- [Same cause: `ProfileService.SaveAsync`. Fixed here, same fix.]

## Approach

[One short paragraph. What changes and where, and why this way over the obvious other way.]

## Tasks

- [ ] [Move validation into `SettingsValidator` and call it from both services]
- [ ] [Return a 400 with the field errors from `SettingsController`]
- [ ] [Show the field errors on the settings screen (Settings > My Package)]

## Out of scope

- [Reworking the settings screen layout]

## Decisions

Choices made during the build that this file left open. Dated, with who decided.

- [16-11-2026: Kept the old 500 path for API clients that send no body (change-build, task 2, agent)]

## Follow-ups

- [Same cause in the import endpoint; needs a migration, so it's a feature]

## Log

Demo site: [URL, start command, log path]

- [Task 1: `abc1234`. Repro test fails before, passes after.]
