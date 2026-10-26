---
name: decision-review
description: >-
  Lists what a human should check after a build: the builder's assumptions, spec deviations,
  workarounds and judgment calls. Read-only. pr-describe runs it for every PR; run it by
  hand for an earlier look. Use when asked what decisions were made, what to check, or what
  needs attention on a finished build.
user-invocable: true
argument-hint: [path to the feature's plan folder, optional]
---

# decision-review

`feature-build` runs unsupervised across many tasks. Each `builder` dispatch reports back
"any decision the plan left implicit that it had to make," and the loop logs those to
`DECISION-LOG.md` (see that skill's step 6). In a fully autonomous run, the PR is the one
checkpoint guaranteed to get a human look, so `pr-describe` always invokes this skill while
writing that PR — nobody has to remember to trigger a separate review step. This skill doesn't
decide anything itself; it decides what's worth *the user's* attention and hands back a short,
ranked list.

## Scope

- IN: read `DECISION-LOG.md`, `BUILD-LOG.md`, and the feature's diff since it branched from
  trunk; surface the subset worth a human's eyes; rank them.
- OUT: fixing anything (no `Edit`/`Write` needed — this is a report), gating a commit (that's
  `reviewer`'s job, already done per task inside the loop), writing the PR description (that's
  `pr-describe` — hand this skill's output to its "Your call" callout instead of duplicating
  the digest in a second file).

## Preflight

1. Resolve the plan folder: the path given in the argument; else match the current
   branch/worktree name against a plan folder the way `feature-build` does (see the project's
   `CLAUDE.md`); else stop and ask.
2. Confirm `BUILD-LOG.md` has at least one entry. If it's empty or missing, nothing has been
   built yet — say so and stop rather than reviewing an empty diff.

## What counts as worth surfacing

Flag something only if a different, equally reasonable choice existed and the outcome could
plausibly matter to the person who owns the feature. Five categories:

- **Assumption** — filled a gap the plan or spec left open, without asking.
- **Deviation** — the implementation does something other than what `SPEC.md` or
  `ARCHITECTURE.md` says it does.
- **Workaround** — routed around a bug, a missing dependency, a CMS-version gap, or a flaky
  test, instead of a clean fix. (A weakened or skipped spec is already an automatic `reviewer`
  `FAIL` inside the loop, so a surviving one here means it slipped through — call that out
  as the top-priority item, not just another workaround.)
- **Judgment call** — ambiguous plan wording resolved one way among several defensible ones.
- **Addition** — built something `SPEC.md` and `ARCHITECTURE.md` never mention. The spec is
  still met, so nothing reads as a deviation, but nobody asked for it.

Some changes are always worth a look, logged or not, even when the spec is met:

- a new database table or migration
- a new package dependency
- a change to the public API: a type or member added, removed, renamed, or made internal
- a new notification handler, background job, or scheduled task
- a new setting
- a new extension point or manifest type
- behavior that runs outside the feature's own screen or endpoint

Skip pure implementation mechanics — variable names, which loop construct, formatting, file
layout inside an already-agreed extension point. Nobody needs to sign off on those.

## Workflow

1. Read `DECISION-LOG.md` end to end. Keep only entries timestamped from this feature's build
   phase (from when `feature-build` cut the branch onward). Earlier entries belong to
   `feature-explore`/`feature-design`/`feature-plan` — the user already weighed in during those phases'
   interviews; don't re-surface settled ground.
2. Read `BUILD-LOG.md` for what each task claimed to verify, as context for the entries above.
3. Read the full diff since the branch point (`git diff <base>...HEAD`), with enough
   surrounding code to judge each flagged item in context, not just the changed lines.
4. Cross-check the diff against `SPEC.md`/`ARCHITECTURE.md` for anything that reads as a
   deviation but was never logged — the builder is supposed to report these, but this step
   catches what leaked through rather than trusting the log is complete. Then go through the
   diff for every change on the always-worth-a-look list above, and flag each one neither
   file mentions as an Addition. For a built screen, compare its screenshot with its mockup
   (`mockups/<screen>.png`) for layout, controls and wording.
5. Sort each surviving item into one of three groups:
   - **Must fix**: broken. It won't build, it fails at runtime, or a test the build log
     claims isn't there. Something built differently from `SPEC.md` is a deviation, not a
     Must fix, unless it breaks something. The gate should have caught these, so this group
     is usually empty.
   - **Your call**: a real choice, where a reviewer could reasonably pick either way.
   - **Checked and fine**: logged or found, and no reason to change it.

   When unsure whether something is broken or a choice, put it under Your call.
6. Write each Your call item as:
   - **Type**: `Design` (how it's built: tables, packages, public API, new services or
     handlers), `Behavior` (what it does: rules, limits, defaults, access), or `UI` (what a
     screen shows or says).
   - **Plan said**: what `SPEC.md`, `ARCHITECTURE.md` or the mockup says, in a few words, or
     "Nothing about <topic>" for an Addition.
   - **Built**: what the code does, with `file:line`.
   - **Options**: two or three, lettered, the recommended one first. Removing or reverting
     the change is an option whenever it's a real one.
   - For a UI item on a screen with a mockup, the mockup and screenshot file names
     (`mockups/<screen>.png`, `screenshots/<screen>.png`).

   Write a Must fix or Checked and fine item as one line with `file:line`.
7. Sort Your call by type: Design, then Behavior, then UI. Within a type, the one with the
   widest effect first: a public API or stored data above code inside the feature. Put an
   unmitigated FAIL-worthy workaround at the top of Must fix.

## Report

Print the groups directly in the reply, in the order Must fix, Your call, Checked and fine —
don't create a new file in the plan folder. Leave out a group with nothing in it. Write each
item following `plain-writing`. If nothing survives steps 1–4, say plainly "nothing needs
your review" and stop; don't pad an empty result with the search process.

## Hand off

Suggested next: a Must fix item goes back to `feature-build` as a fix round first. Then
`pr-describe`, which puts Your call at the top of the PR, then open the PR per
`git-workflow`.

This is the post-build half of plan scrutiny; `feature-interrogate` is the pre-build half,
run by hand before `feature-build` on a plan worth the extra confidence. Neither replaces the
other: this one reads what actually got decided during a real build, that one stress-tests
intent before any code exists.
