# CLAUDE.md

[One-line project summary — ask if there isn't one already, or infer from an existing
README/package description.]

## Stack

- Umbraco CMS: [version(s) targeted — TODO if undetected]
- Database: [SQL Server only | SQL Server + SQLite — TODO if undetected]
- Frontend: [Lit + UUI, if a Client/ folder exists — otherwise omit this section]

## Build & test

```bash
dotnet build <solution>.slnx
dotnet test <solution>.slnx
dotnet format <solution>.slnx --verify-no-changes   # lint/format check
```
[Fill in the real commands once detected or set up by project-init's wizard; TODO otherwise. Add
the frontend lines (build, `npm test`, `npm run lint`, `npm run format`) only if a frontend
project exists, and the e2e line (how to start the demo site, then `npx playwright test`) only
if e2e tests exist.]

The `builder` runs the lint/format check before reporting a task done.

## Feature workflow

This project uses the Umbraco Devkit. Feature plan folders live at:
`[the path convention settled on in the interview]`
Closed plans are archived under: `[archive path, default docs/archive/]`
Ideas for later live in: `[ideas path, default docs/ideas/]`

Pipeline: `/feature-explore` → `/feature-design` → `/feature-plan` → `/feature-build`, then
`/feature-close` once the feature's PR is merged or the plan is dropped. Each phase owns its
own file in the feature's plan folder (`BRIEF.md`, `ARCHITECTURE.md` + `SPEC.md`,
`STORIES.md` + `PLAN.md`, `BUILD-LOG.md`) — see the devkit's README for the file-ownership
table.

**Ideas:** a note about something worth doing later, not yet being planned. Any shape, any
length, no template or status: an idea only turns formal when `/feature-explore` starts from
it. Always commit an idea once written (asking first, as for any commit), so the team can see
it. `/feature-close` archives an idea once every part of it has been built or dropped.
An idea's file name (without `.md`) is its name. Refer to it by that name alone, never by path,
so moving it to the archive breaks nothing; to find it, look in the ideas folder, then the
archive. A new idea's name must not already be used there.

**Plans and the archive:** the plans folder holds only live work. The archive is history: it
records what was planned at the time, not how the code works now. Read it only to answer why
something was done, never as current design. A decision that outlives its feature goes in
`.claude/memory/` or a nested `CLAUDE.md`. Two link rules keep this safe:
- **Code never links to repo files or memory.** A comment that needs a "why" says it in a line
  or two. A longer reason goes in the nearest `CLAUDE.md`, which Claude reads anyway.
- **Docs that last never link into the plans or archive folders.** Any `CLAUDE.md`,
  `.claude/memory/`, and reference docs link to each other instead.

A plan's folder name is its name (and its branch name). One plan or idea refers to another by
name alone, never by path, so archiving either breaks nothing; to find a plan, look in the
plans folder, then the archive.

**Branch/worktree per feature:** new features start from `[trunk branch — the repo's default
branch, or a long-lived vN/dev line for a branch-per-major project]`. Plan-folder files stay
uncommitted through `feature-explore`/`feature-design`/`feature-plan`. `feature-build` commits the plan
folder to trunk and cuts the feature's branch/worktree — named after the plan folder — the
moment building actually starts, not before (see `git-workflow`'s "Branch/worktree per
feature" section). [If a `WorktreeCreate` hook is configured for this project, name it here —
it decides the real branch name and location. Otherwise `feature-build` falls back to a plain
`git checkout -b <feature-slug>` off trunk.]

**Finding the current feature's plan folder:** once a branch/worktree exists for a feature,
its name already carries the feature slug — strip a leading `vN/` and/or type prefix such as `feat/`,
`feature/`, or `topic/` (see `git-workflow`'s branch-naming rules) and check whether the plan-folder path above has a
matching `<remainder>/` folder. If it does, that's the current feature — no need to ask which
one. Only fall back to asking when nothing matches (still on trunk, or the branch/worktree name
doesn't correspond to any plan folder).

## Conventions

[TODO — filled in as feature-explore/feature-design surface real decisions worth recording
here permanently, e.g. folder structure rules, naming conventions specific to this project.]

## Project memory

Two places a decision lives, by scope:
- **Scoped to one directory/module** → a nested `CLAUDE.md` in that directory. Claude reads
  the nearest one walking up from whatever it's editing (`reviewer` does this on every task).
- **Project-wide, but not worth permanently bloating this file** → `.claude/memory/` — one
  file per entry, indexed in `.claude/memory/MEMORY.md`. See `.claude/memory/README.md` for
  the format.
