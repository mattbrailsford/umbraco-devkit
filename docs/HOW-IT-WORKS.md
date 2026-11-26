# How it works

The ideas behind the devkit, for when you want more than the [README](../README.md) gives
you.

## How the skills connect

Code only changes through one of these flows, and all of them go through the
[builder/reviewer gate](#the-builderreviewer-gate) (`quick-fix` skips it for a text-only
change):

- **The pipeline**, `feature-explore` → `feature-design` → `feature-plan` →
  `feature-build`, for a feature or any change that needs a design.
- **`quick-fix`**, for a small fix of one concern. It hands over to `change-build` or the
  pipeline if the fix turns out bigger.
- **`change-build`**, for the size in between: a fix or small change across several files,
  where the way to do it is clear. It plans the change in one file,
  `docs/changes/<slug>.md`, asks once, then builds it task by task. It hands over to the
  pipeline if the change needs a design.
- **`major-upgrade`**, for moving to a new Umbraco major. It also lists the pages and
  screenshots of the package's own docs that the upgrade makes wrong.
- **`change-backport`**, for landing a change that's already merged on one version line on
  another.
- **`advisory-fix`**, for a confirmed security vulnerability. It follows the project's own
  security process from `CLAUDE.md`, puts the fix under [embargo](#plan-folders-branches-and-worktrees)
  so it can only reach the advisory's private fork, keeps every public word neutral, works out
  the affected and fixed versions, and times the release. Its notes live in the repo's `.git`
  folder, where no push can carry them.

Every other skill you run works around those flows and never changes code itself:

- **Finds the work and routes it.** `investigate-bug` proves a bug's cause, then says which
  flow should fix it. `issue-triage`, `issue-backlog`, and `issue-resolve` take tracker
  issues from new to a started fix.
- **Reviews and explains it.** `pr-review` runs the same reviewer over a PR from outside the
  team. `feature-interrogate` adversarially stress-tests a plan before it's built;
  `decision-review` pulls out what a human should look at after it's built — the same job,
  run at opposite ends of the pipeline. `pr-describe` writes the PR description, opening with
  the choices `decision-review` found that a reviewer should check, and
  `pr-demo` starts a PR on the demo site so you can click through it yourself.
  `markdown-preview` opens a plan file or folder in the browser, drawn by GitHub and
  refreshed as it changes; the planning steps offer it once they've written their file.
  You can comment on any line there and send the batch to Claude, which fixes the doc and
  replies on each comment.
  `dependency-review` sorts Dependabot PRs, security alerts, and out-of-date packages by what
  each touches, and hands chosen bumps to `quick-fix`.
- **Tidies up after.** `feature-close` moves a closed plan out of the plans folder once
  its PR is merged or the plan is dropped.
- **Sets up and ships.** `project-init` prepares a project, `github-init` its first public
  repo, and `umbraco-marketplace` its Marketplace listing.
- **Learns from a session.** `skill-report` turns a mistake a skill should have caught into
  an issue on the devkit's tracker, which becomes an eval. `project-retro` handles the rest:
  a trap that's the project's own, or knowledge worth keeping even when nothing went wrong,
  saved to [project memory](#project-memory) instead.

You don't have to pick. Describe what you want and Claude picks the skill from its
description.

## One plan folder per feature

Each pipeline step owns one file in a per-feature folder, by default
`docs/plans/<feature-slug>/`. To use a different path (worktree-relative, or scoped to a
monorepo package), say so once in your project's `CLAUDE.md` and every step follows it.

| File | Owned by |
|---|---|
| `README.md` | `feature-explore` creates it; every step before `feature-build` updates its own line; `feature-close` adds a status line |
| `BRIEF.md` | `feature-explore` |
| `ARCHITECTURE.md`, `SPEC.md`, `mockups/`, `diagrams/` | `feature-design` |
| `STORIES.md`, `PLAN.md` | `feature-plan` (`feature-build` only ticks `PLAN.md`'s task checkboxes) |
| `DECISION-LOG.md` | every step appends |
| `BUILD-LOG.md`, `screenshots/` | `feature-build` (its `smoke-tester` agent takes the screenshots) |
| `PR-DESCRIPTION.md` | `pr-describe` |

Three rules make this work:

- **Re-entrant.** Re-run a step to refine its file. It never starts over.
- **One owner per file.** Two steps, or two sessions, never edit the same file, so there's
  nothing to merge-conflict over.
- **Stop, don't guess.** A step missing its input sends you back to the step that owns it.

Because every step reads its input from the plan folder, not the chat, you can `/clear` between
steps and lose nothing. Each hand-off suggests it, with the command to run next. The same goes
for a bug: `investigate-bug` puts its report on the tracker, so `issue-resolve <issue ID>` can
start fresh.

Review comments left in `markdown-preview` follow the same ownership. A comment on a file the
running step doesn't own is left for the step that does, and that step picks it up as input
the next time it runs. Comments are kept in the worktree's `.umbraco-devkit/` folder, which git ignores, never in the plan.
Before a step builds on a plan, or `feature-close` archives one, it checks for unresolved
comments: one left for an earlier step sends you back to that step, and ones waiting on you
are raised in a single question.

Outside the feature folders, `feature-design` also owns `docs/mockups/starters/`: mockup
starters for a product's own screens (a Copilot sidebar, a flow editor) that the general
starters can't draw. One is saved only when a screen is both distinct and something features
keep landing on.

### Before a plan: ideas

Something worth doing later, but not being planned yet, goes in `docs/ideas/` as a loose note
and gets committed so the team can see it. No template and no status: ideas stay quick.
`feature-explore` can start from one, and the brief records which part of the idea it builds.
An idea can feed more than one feature. Everything refers to an idea by its file name alone,
never its path, so it can move to the archive without breaking anything. Plans work the same
way: a plan's folder name is its name, and other plans refer to it by that.

### When a plan closes

Once a feature's PR is merged, or the plan is dropped or replaced, `feature-close` moves the
folder to `docs/archive/plans/<feature-slug>/`. `major-upgrade` does the same for its upgrade
file, into `docs/archive/upgrades/`, and `change-build` for its change file, into
`docs/archive/changes/`. This keeps the plans folder to live work, so an active
plan is easy to find, and Claude doesn't mistake an old design for the current one.

Before the move, it adds one status line to the folder's `README.md` (shipped, abandoned, or
superseded), and copies any decision that outlives the feature into project memory or a
nested `CLAUDE.md`. If the plan started from an idea and nothing in it is left to do, the idea
moves to `docs/archive/ideas/` too. Code never links to repo files or memory: a comment gives its reason
itself. `CLAUDE.md` files and memory link to each other, never into a plan or the archive. So
nothing breaks when a plan moves, and the reviewer flags a new link that would.

## The builder/reviewer gate

`feature-build` hands each task in `PLAN.md` to a `builder` agent, then a `reviewer` agent
checks the change. The reviewer has no edit tools on purpose: it can only read, run the build
and tests, and return `PASS` or `FAIL`. A reviewer that could patch its own findings would
stop being a gate. Once every task is built, one more review covers the whole branch, to
catch problems that build up across tasks.

Between the builder and the reviewer, a script runs cheap checks a reviewer shouldn't spend a
round on: a file that isn't UTF-8, a code comment linking into a plan folder, `unsafeHTML`
with nothing sanitizing it, a new file git doesn't track. Others catch shortcuts to a green
build: a test switched off, a warning suppressed with no reason, an empty `catch`, a fixed
wait in a test. A finding goes straight back to the builder. One the builder can't fix, it
keeps with a reason, and the reviewer judges it. The checks live in the plugin's `checks/` folder, one file each. A project adds its
own in `.claude/checks/`, and turns one off in `.claude/checks/config.json`.

A failed task goes back to a fresh builder, and the next review looks only at what that
round changed, plus whether the old findings were fixed. Reviewing the whole task every round
mostly turns up older code and the loop never settles. After three failed rounds, the builder
is told to rethink the approach instead of patching again; if that fails too, the build
stops and reports.

After a pass, a `smoke-tester` agent runs the change through the real entry point (an e2e
test or the demo site) and takes the screenshots for the PR. It looks at every image and
reports back in words, so the session running the build stays small: that session runs every
task, and whatever it reads stays in its context until the build ends. The builder and
reviewer keep their reports short for the same reason.

The build starts the demo site once, before the first task, and notes it at the top of
`BUILD-LOG.md`. Every builder and smoke-tester uses that one site instead of starting its
own, and it restarts only after a task changes server code. When a site won't serve the
change, the smoke-tester restarts it once and then reports, rather than rebuilding in a loop.

The same agent works for `feature-design`. When a design rests on how something outside the
package behaves (a CMS picker in a new place, when a notification fires, what an API
returns), a `builder` writes a throwaway spike on the demo site and the `smoke-tester` tries
it before the plan depends on it. Design only reads their short reports.

`quick-fix` uses the same reviewer for small fixes. `change-build` uses the whole gate for a
change planned in one file. `major-upgrade` uses the whole gate for
a move to a new Umbraco major: it lists the breaking changes that hit the project in
`docs/upgrades/v<major>.md`, then builds that list task by task, green at every commit.

## Project memory

Some facts don't belong in a feature's plan folder or in `CLAUDE.md` forever. `project-init`
sets up `.claude/memory/` for those:

- **`decision`**: a standing project-wide decision.
- **`gotcha`**: a repeatable mistake, so the next build doesn't repeat it. `feature-build` and
  `quick-fix` save one after a reviewer finding; `investigate-bug` saves one after a proven
  bug; `project-retro` catches whatever a session left uncaptured.
- **`reference`**: a pointer to an outside system.

A convention for one folder still goes in a `CLAUDE.md` in that folder. The reviewer reads
the nearest one on every task. `.claude/memory/README.md`, created by `project-init`, explains the
format.

## Plan folders, branches, and worktrees

These solve different problems. A worktree keeps two features' *files* apart. A plan folder
keeps a feature's *decisions* together. Because each plan folder has its own path, they never
collide, with or without worktrees.

`feature-explore`, `feature-design`, and `feature-plan` never touch git. A feature you explore and then
drop costs nothing. `feature-build` is where git comes in: on the first build, it asks
before committing the plan folder to your trunk branch, then cuts a branch or worktree named
after the feature. The plan ends up in the feature branch's history because it was committed
just before the branch was cut. `git-workflow`'s "Branch/worktree per feature" section has
the full reasoning.

Every skill asks before it commits to trunk, but a skill is advice Claude can miss. The
plugin's `trunk-gate` hook backs it up. Before any commit, merge, or push that lands on a
protected branch (`main`, `master`, the remote's default branch, `support/*`, `vN/main`,
`vN/dev`), Claude Code itself asks you. A force-push or delete of one is blocked outright. So
the trunk commit `feature-build` makes can ask twice: once in chat, once from the hook. A
project that doesn't want it sets `UMBRACO_DEVKIT_TRUNK_GATE=off` in the `env` block of its
`.claude/settings.json`.

A security fix needs a stronger guard: it must not reach a public remote until the advisory is
published. An embargo, keyed by the advisory's GHSA id, marks the branches that hold the fix.
It lives in the repo's local git config, so it's never committed and covers every worktree.

```bash
node <plugin>/hooks/embargo.mjs add GHSA-xxxx-xxxx-xxxx --branch v18/hotfix/x --branch v17/hotfix/x --ticket SEC-123
node <plugin>/hooks/embargo.mjs status
git embargo lift                                       # a person lifts it, once approved
```

`add` sets up the `git embargo` shortcut in the repo. `lift` shows what the embargo protects
and asks you to type its id, at your own terminal: it won't run without one, and the hook
stops Claude running it, so lifting stays a human step. Once no embargo is left, it removes the
guard and the shortcut. By hand, `git config --remove-section devkit-embargo.<id>` does the
same.

The only remote allowed to receive the fix is the advisory's private fork. GitHub names it after
the repo and the id (`<owner>/<repo>-ghsa-xxxx-xxxx-xxxx`), so the guard works it out from the
id and the repo's own remotes. Nothing else needs setting, and nothing can widen it. With no
private fork (the code and the tracker live in different places), key the embargo by the
internal ticket instead, and nothing can be pushed until you lift it.

Two guards read it, and both block instead of asking, since one quick "yes" would publish the
fix:

- The `embargo-gate` hook stops Claude from pushing the fix, or any branch holding it (merged,
  cherry-picked or reworded), anywhere but the private fork, and from opening a public PR with
  it. It also stops Claude from lifting the embargo.
- A git `pre-push` hook, which `add` installs, stops the same push from a terminal or editor.
  It isn't installed when the repo already has its own pre-push hook or sets `core.hooksPath`;
  `add` says so.

Both also read the words that go public with the fix: commit, tag and merge messages, new
branch and tag names, PR and issue text, and the messages of pushed commits, even to the
private fork, since its commits go public later. An advisory id (any GHSA or CVE id, the
embargo's key or its `--ticket`) is blocked. Words that point at a security fix
("vulnerability", "bypass", "XSS") get a question from the hook and a warning from `pre-push`,
because plain fixes use them too. Neither can spot a vague hint, so neutral wording is still
on whoever writes the message.

`git push --no-verify` skips the pre-push hook, so the guard catches mistakes, not someone set
on getting round it.

## Building on top

The devkit stops where most projects start to differ. As a project grows, it usually
needs:

- **A release pipeline.** Release branches, changelogs, multi-product manifests. Each
  project's release steps live in that project, not here.
- **Branch cleanup automation.** `feature-build` already cuts a branch per feature. A project
  can add its own `WorktreeCreate`/`WorktreeRemove` hooks for naming, copying local files,
  and cleaning up after merge.
- **Project-specific scaffolding.** Every non-trivial project ends up with a few of these.

Add them when the need shows up, not on day one.
