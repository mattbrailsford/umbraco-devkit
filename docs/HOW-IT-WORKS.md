# How it works

The ideas behind the devkit, for when you want more than the [README](../README.md) gives
you.

## How the skills connect

Code only changes through one of four flows, and all four go through the
[builder/reviewer gate](#the-builderreviewer-gate) (`quick-fix` skips it for a text-only
change):

- **The pipeline**, `feature-explore` → `feature-design` → `feature-plan` →
  `feature-build`, for a feature or any fix too big to do in one go.
- **`quick-fix`**, for a small fix of one concern. It hands over to the pipeline if the fix
  turns out bigger.
- **`major-upgrade`**, for moving to a new Umbraco major.
- **`change-backport`**, for landing a change that's already merged on one version line on
  another.

Every other skill you run works around those flows and never changes code itself:

- **Finds the work and routes it.** `investigate-bug` proves a bug's cause, then says which
  flow should fix it. `issue-triage`, `issue-backlog`, and `issue-resolve` take tracker
  issues from new to a started fix.
- **Reviews and explains it.** `pr-review` runs the same reviewer over a PR from outside the
  team. `feature-interrogate` adversarially stress-tests a plan before it's built;
  `decision-review` pulls out what a human should look at after it's built — the same job,
  run at opposite ends of the pipeline. `pr-describe` writes the PR description, and
  `pr-demo` starts a PR on the demo site so you can click through it yourself.
  `markdown-preview` opens a plan file or folder in the browser, drawn by GitHub and
  refreshed as it changes; the planning steps offer it once they've written their file.
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
| `README.md` | `feature-explore` creates it; every step updates its own line; `feature-close` adds a status line |
| `BRIEF.md` | `feature-explore` |
| `ARCHITECTURE.md`, `SPEC.md`, `mockups/`, `diagrams/` | `feature-design` |
| `STORIES.md`, `PLAN.md` | `feature-plan` (`feature-build` only ticks `PLAN.md`'s task checkboxes) |
| `DECISION-LOG.md` | every step appends |
| `BUILD-LOG.md`, `screenshots/` | `feature-build` |
| `PR-DESCRIPTION.md` | `pr-describe` |

Three rules make this work:

- **Re-entrant.** Re-run a step to refine its file. It never starts over.
- **One owner per file.** Two steps, or two sessions, never edit the same file, so there's
  nothing to merge-conflict over.
- **Stop, don't guess.** A step missing its input sends you back to the step that owns it.

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
file, into `docs/archive/upgrades/`. This keeps the plans folder to live work, so an active
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

A failed task goes back to a fresh builder, and the next review looks only at what that
round changed, plus whether the old findings were fixed. Reviewing the whole task every round
mostly turns up older code and the loop never settles. After three failed rounds, the builder
is told to rethink the approach instead of patching again; if that fails too, the build
stops and reports.

`quick-fix` uses the same reviewer for small fixes. `major-upgrade` uses the whole gate for
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
