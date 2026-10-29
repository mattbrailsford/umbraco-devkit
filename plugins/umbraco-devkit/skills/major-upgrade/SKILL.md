---
name: major-upgrade
description: >-
  Moves an Umbraco package to a new CMS major (for example 17 to 18): finds the breaking
  changes that hit it, writes an ordered checklist in `docs/upgrades/v<major>.md`, and works
  through it with the builder and reviewer agents. Use for "upgrade to Umbraco N", "support
  v18", a new major's beta or RC, or moving from one RC to the next. Not for minor or patch
  bumps.
user-invocable: true
argument-hint: <target CMS major, e.g. 18>
---

# major-upgrade

A CMS major upgrade is the same features on a new base, so the `feature-explore` → `feature-design` →
`feature-plan` pipeline doesn't fit it, and it's far too big for `quick-fix`. This skill is its
own lane: it plans the upgrade from Umbraco's published breaking changes, then builds it with
the same builder → reviewer → smoke → commit gate as `feature-build`.

## Scope

- IN: one hop to one target major. Dependency and target framework bumps, code changes forced
  by breaking changes or removed obsolete APIs, the frontend's `@umbraco-cms/backoffice`
  bump, the package's own compatibility markers (version, dependency range, marketplace
  metadata, README), and the third-party dependency bumps the user picks from inventory step
  10.
- OUT: new features, refactors the upgrade doesn't force, and dropping an older major the
  project still supports. Note those in the upgrade file's "Follow-ups" section instead.
  Releasing the upgraded package is also out of scope; it's the project's own release steps.

## Argument

`$ARGUMENTS` is the target major (`18`, `v18`). If empty, ask.

**First run or refresh?** If `docs/upgrades/v<major>.md` already exists, an earlier run
upgraded to a CMS release of this major, usually a beta or RC. This run is a **refresh**: move
to the newest CMS release of the major (the next RC, or the final release) and handle only
what changed since the release the file records. Skip to "Refresh" below. If the file doesn't
exist and the project already targets that major, say so and stop. If the file targets the
major's final release and its PR is merged, the upgrade is done: skip to "Archive" instead.

## Preflight

1. **Current version.** Read the exact `Umbraco.Cms.*` version from `Directory.Packages.props`
   or the `.csproj` files, and `@umbraco-cms/backoffice` from the frontend's `package.json`
   if there is one. If projects disagree, stop and report it; fix that first.
2. **Which CMS release to target.** List the target major's releases:
   ```bash
   gh release list -R umbraco/Umbraco-CMS --limit 100 | grep "release-<major>\."
   ```
   Take the newest. If it's a beta or RC, that's the normal way to start: the package can
   ship its own pre-release against it, and a later run refreshes to the next RC and then the
   final release. Tell the user which release you'll target and record it in the upgrade
   file. If the major has no release yet, stop: there's nothing stable enough to build on.
3. **Is the hop allowed?** Use `umbraco-docs` to read the target major's breaking-changes
   page, `<major>/umbraco-cms/get-started/upgrading-and-migrating/version-specific.md`. Its
   "Preparation for Upgrade" section names the oldest version it upgrades from. If the project
   is older than that, stop: upgrade to the named version first (run this skill for that
   major), then come back. Before a major's final release, the docs often don't have this
   page yet. Say so, and ask the user to confirm the hop instead of assuming it's fine.
4. **Other Umbraco dependencies.** For every other Umbraco package the project depends on
   (Forms, Commerce, community packages), check NuGet for a release that supports the target
   release. For a pre-release target, check Umbraco's pre-release feed too
   (`umbraco-dependencies`' "A pre-release floor"). A missing one is a blocker: record it and
   ask before going on.
5. **Branch.** Read `git-workflow`'s "Umbraco packages and version tracking" section and the
   project's `CLAUDE.md` to see how it carries more than one major.
   - Branch-per-major: the new line (for example `v18/dev`) is cut from the current major's
     line. Check it doesn't already exist.
   - Single line: a short-lived branch such as `chore/upgrade-v18`.

   Confirm the working tree is clean, then **ask the user to confirm the branch name and its
   base before creating it.**

## Inventory: write `docs/upgrades/v<major>.md`

Build the list of what has to change before touching code. Only list what hits this project.
A breaking change in an area the project never uses is noise.

**The CMS repo is the source of truth for what changed. The docs are a cross-check.** The
docs are often written after the code ships, and before a final release they can be missing
or incomplete. Never treat "not in the docs" as "not a breaking change".

1. **Target framework, SDK, and shared dependencies.** Read the CMS's `TargetFramework` at
   the target release tag (`umbraco-cms-source`, `Directory.Build.props` at the repo root).
   If it differs from the project's, the upgrade includes a .NET bump. Check `global.json`
   too, if the project has one.

   Then match every dependency the project shares with the CMS to the CMS's version at the
   target tag. The upgrade moves the package's floor to the target release, so
   `umbraco-dependencies`' "Locked to the CMS" says which dependencies these are, NuGet and
   npm, and how to read their versions. A shared package the CMS doesn't list is brought in
   by one that it does; find its version with `dotnet list package --include-transitive`
   once the bump restores. If the client lists its own copy of a library the backoffice ships
   under `external/*`, suggest importing from that path instead as a follow-up.

   List every shared dependency with its current and target version in the inventory.
2. **What changed in the CMS.** No single source lists every break: labels, release notes
   and the docs each miss some. Work from the CMS diff between the two tags, using the local
   clone (`umbraco-cms-source` has how to find it as `$CMS`). The commands for each part
   are in `references/finding-breaks.md`.
   - **Labelled PRs.** Umbraco labels breaking PRs `category/breaking`. List the ones in
     the target release and not in the current one. Start the search at the oldest commit
     in the range, not at the current major's release date: work for the next major
     starts before the current one ships. A PR merged to a feature branch that was later
     squash-merged is in no tag's history; keep it as "probably in" and check the target
     tag for what it changed. With no clone, filter the list by base branch instead:
     `v<major>/dev`, `release/<major>.*`, and `v<major>/feature/*`.
   - **CMS types the package uses.** List every CMS type the package names, C# and
     backoffice. Diff each one's file between the tags. Every removed or changed public or
     protected member the package uses is an entry, labelled or not.
   - **Subsystems the package extends.** Where the package subclasses or composes CMS
     building blocks (the block editor's managers, workspaces and value converters; search
     providers; trees), a change anywhere in that subsystem can break it, even one that
     still compiles. Group these by subsystem and diff the whole folder, not only what the
     PRs name. Read the behavior changes. Each subsystem gets its own scenario in the smoke.
   - **CMS data migrations.** Read every migration the target adds to `UmbracoPlan.cs`. If
     one rewrites data shaped like data the package stores (block JSON, property values it
     owns), add a task to check the package's data after it, and include it in the upgrade
     smoke ("Finish").

   For each entry, grep the project for what it changed or removed. Name the PR behind an
   entry from history (`git log -S` on the changed line), never from a PR title: titles
   don't say everything a PR touched. Merge-ups and cherry-picks repeat a change; keep one
   entry per PR.
3. **Release notes.** Each beta, RC, and final release of the target major has a
   "💥 Breaking Changes" section (`gh release view <tag> -R umbraco/Umbraco-CMS`). Read
   every one in the range. The list to work from is everything step 2 found plus every PR
   these sections name; a PR here that step 2 missed gets the same treatment.
4. **The docs page.** Read the target major's section of the breaking-changes page from
   preflight step 3, if it exists. It covers changes no single PR shows: settings with new
   defaults, migrations that now run automatically, steps to take before upgrading. Grep the
   project for what each entry names.
5. **Obsolete APIs.** Collect `CS0618` warnings twice: on the current version now, and on the
   target release once the bump task compiles. Umbraco's `[Obsolete]` messages name the
   replacement and the major that removes the member ("Use X instead. Scheduled for removal
   in Umbraco 19."). Every warning is a task, whichever major it names: move to the
   replacement now, while the upgrade is open. The second build catches APIs the target
   major newly made obsolete, which no earlier version warned about.

   Some removals carry no `[Obsolete]` at all, only a `// TODO (V<target>)` comment in the
   CMS at the current tag, often on a default interface member or an overload. Grep for
   those too; each one the package uses is an entry.

   **Spike compile.** In a scratch worktree, bump the CMS packages to the target and build
   once. Fix nothing. Every error not already in the inventory is a new entry, and any
   `CS0618` from projects that compiled is an early look at the second list. Remove the
   worktree after. This is a cross-check, not the bump task.

   Leave a warning as a follow-up only when its replacement doesn't exist in every CMS
   version the branch builds against (a branch that targets two majors at once). Say which
   version is missing it.
6. **Frontend.** If there's a backoffice client, give it the same care as the C#. Most
   frontend breaks don't fail the build: a manifest field the backoffice no longer reads, or
   a component tag that no longer exists, just renders nothing. Check each of these at the
   target tag (`umbraco-cms-source`, under `src/Umbraco.Web.UI.Client/`), and treat every hit
   as a task (`umbraco-backoffice-conventions` has the client build rules):
   - **Type-check against the target.** In a scratch copy of the client, set
     `@umbraco-cms/backoffice` to the exact target version. Set its peers to the target's
     first (`npm view @umbraco-cms/backoffice@<target> peerDependencies`; the project's
     lockfile still has the current major's), or the install fails with `ERESOLVE`. Then run
     `tsc --noEmit`. Every error is an entry: removed exports, moved import paths, changed
     contexts and manifest `meta` types. Do this first. A bundler build doesn't type-check,
     and a deprecation lint can't see an API that's already gone.
   - **Import paths.** Compare the `exports` map in `package.json` at the two tags for every
     `@umbraco-cms/backoffice/*` path the project imports. A path that's gone or moved is a
     task.
   - **`@deprecated` APIs.** The TypeScript compiler doesn't warn about these, so they're
     easy to miss. Run ESLint with `@typescript-eslint/no-deprecated` (the rule the CMS
     client uses itself) on the current version and again after the bump, like step 5's two
     builds. If the project's lint config lacks the rule, run it once from the command line
     rather than changing the config. Leave out generated API client folders (wherever the
     project's OpenAPI generator writes): they're regenerated, not fixed by hand. Umbraco's `@deprecated` tags name the major that
     removes the API ("Scheduled for removal in Umbraco 19").
   - **Runtime deprecations.** Some backoffice deprecations only show in the browser. The
     CMS logs them with `UmbDeprecation` as a console warning that starts "Umbraco
     Backoffice:" and names the removal version. Newer releases add an "Origin:" line naming
     the package when the caller is under `/App_Plugins/`; on older ones, match the warning
     to the package's code yourself. Collect them during the smoke (see "Build").
   - **Manifests.** Every extension `type`, `kind`, `meta` field, and condition `alias` the
     package registers must still exist at the target tag. Validate `umbraco-package.json`
     against the `umbraco-package-schema.json` that ships in the target's
     `@umbraco-cms/backoffice` npm package (a JSON-schema validator run with `npx`, not a new
     dependency).
   - **Elements and contexts.** Every `umb-*` and `uui-*` tag the package's templates use,
     and every context token it consumes, must still exist at the target tag. Lit templates
     aren't type-checked, so a renamed tag fails silently.
   - **UUI and styling.** If the target ships a new UUI major, read its breaking changes
     and grep the package for each changed component, attribute, and `--uui-*` CSS custom
     property.
7. **Persistence.** If the project has EF Core migrations and step 1 moves EF Core, note
   it: `ef-core-data`'s provider checks apply to the smoke.
8. **Compatibility markers.** List every place the supported CMS version is written down: the
   package's own version (per the project's choice in `git-workflow`), NuGet dependency
   ranges (including ranges or exact pins on the repo's own sibling packages), package
   references in any `dotnet new` template the repo ships, `umbraco-marketplace.json`,
   README compatibility tables, any CI matrix, and the `target-branch` entries and ignore
   list in `.github/dependabot.yml` (`umbraco-dependencies`' "Dependabot").
   Against a CMS pre-release, the package's own version is a pre-release too (for example
   `19.0.0-rc1`), and its dependency range must allow the CMS pre-release.

   A demo or test site the smoke uses (even a gitignored one) needs the target CMS too, so
   list it as part of the bump task. It isn't a compatibility marker: it says nothing about
   what the package supports.
9. **The package's own scheduled removals.** Work out the package version this upgrade will
   release (from step 8). Then find everything the package itself deprecated with a removal
   version at or below it. With version-aligned versioning that's the target CMS major; with
   independent SemVer, ask the user which version this release will be:
   - C# `[Obsolete]` members whose message names that version
     (`umbraco-package-conventions` sets the "Will be removed in vN" format).
   - Frontend exports tagged `@deprecated` with that version, and the runtime warnings that
     go with them (`umbraco-backoffice-conventions`).
   - Old manifest aliases kept registered only so other packages' references keep working.

   Each is a removal task. Remove nothing that names a later version, and nothing that
   doesn't name a version at all: list those as follow-ups for the user to decide. Every
   removal is a breaking change for the package's consumers, so record each one in the
   file's "Breaking changes for consumers" section.
10. **Third-party dependencies.** A new package major is when consumers expect breaking
    changes, so it's the time for the dependency updates a minor release can't take. Only
    when step 9 says this release is a major for the package: always with version-aligned
    versioning; with independent SemVer, only if the user chose a new major. Otherwise skip
    to the forced bumps below.

    Look only at **shipped** dependencies (`umbraco-dependencies`' kinds, sorted at the
    target tag, since a CMS major can lock or unlock a package) where the update is:
    - a new major version, or a new minor of a `0.x` package, which can break just the same;
    - or something held back for this moment: a `.github/dependabot.yml` ignore entry with
      `update-types`, a manifest comment ("bump to 3.0 when..."), a "leave" from an earlier
      `dependency-review`, or a Follow-up in the previous upgrade file
      (`<archive-path>/upgrades/`). Existing npm `overrides` count too: recheck whether each
      is still needed.

    Dev-only updates and shipped patches and minors can move any time; leave them to
    `dependency-review`. Find versions the way its "Gather updates with no PR" step does,
    starting from the version that actually ships (for bundled npm, the lockfile's resolved
    version, not the range floor). Look past the stable filter where it misleads: a current
    pre-release, a pre-release that's the real target, and a package deprecated in favor of
    a new id (nuget.org and `npm view <name> deprecated` name the successor).

    For each candidate:
    - **Framework.** The new version must work on the target framework from step 1: a
      matching target, a lower one, or `netstandard`. It needn't list it by name.
    - **Locked packages, at any depth.** Walk the new version's dependency chain
      (`umbraco-dependencies`' nuspec lookup) for any package the CMS ships at the target
      tag, and compare versions. If the current version already overshoots, say so and show
      the trade-off for the user to decide, as in "When the package is already off the
      floor".
    - **Breaking changes.** Read its release notes (the repository URL in its nuspec or
      `package.json`, its GitHub releases, or its CHANGELOG).
    - **Consumers.** Grep the package's public signatures for the dependency's types. If
      they appear, or consumers are likely to reference the dependency themselves, the bump
      is a breaking change for them.

    **Forced bumps** are different: when the current version doesn't run on the target
    framework, or needs a locked package above the target's version, the upgrade can't build
    without moving it. Those go in task 2 with the CMS bump, with no picking.

    Show the user the list (dependency, current, newest, what breaks) and let them pick.
    Packages that release together (`react` with `react-dom`, an SDK family) are one entry and
    one task. Record each picked bump that's breaking for consumers in "Breaking changes for
    consumers". What isn't picked goes in "Follow-ups".
11. **Stopgaps waiting for a major.** Same condition as step 10: only when this release is a
    major for the package. Grep for `TODO(stopgap):`, or the project's own debt marker if
    its `CLAUDE.md` names one (`quick-fix` writes these when the user picks a stopgap over
    the proper fix). Each comment says what it hides and what the proper fix is. Mark the
    ones whose proper fix is a breaking change for consumers (a public signature, a stored
    data shape, a manifest alias, a setting): a major is the release where those can land.

    Show the user the list (marker, where, the proper fix, breaking or not) and let them
    pick. Nothing goes in by default: an upgrade that takes on every old shortcut never
    finishes. Each picked one is a task, and its proper fix removes the marker comments. Record
    the breaking ones in "Breaking changes for consumers". What isn't picked goes in
    "Follow-ups".

Write the file from `templates/UPGRADE.md`. Order the tasks so **every task ends in a green
build**:

1. Fix obsolete and `@deprecated` usages, C# and frontend, while still on the current
   version. Each replacement API already exists there, so this lands green and shrinks the
   bump.
2. Bump the target framework and packages, with every shared dependency at the CMS's
   version (step 1) and any forced third-party bump (step 10), and fix what no longer
   compiles. This is the one big task. Split it by
   project if the solution has several.
3. Move off APIs the target release made obsolete or `@deprecated` (the second build and
   lint run in steps 5 and 6). Add these tasks once the bump compiles; you can't see them
   before.
4. Behavior changes: breaking changes that still compile but act differently (a setting's new
   default, a renamed URL, a changed notification, a subsystem change or data migration from
   step 2).
5. The frontend bump and its fixes: import paths, manifests, elements and contexts, UUI.
   Runtime deprecation warnings found in the smoke get added as tasks here.
6. Third-party dependency bumps the user picked (step 10), one task per dependency or family
   that releases together. These go after the CMS work, so a failure points at the
   dependency, not the CMS.
7. Remove the package's own deprecated code scheduled for this version (step 9), after the
   other code changes, so a test failing here points at the removal.
8. Proper fixes for the stopgaps the user picked (step 11), one task each, after the
   removals, so a failure points at the fix.
9. Compatibility markers.

Show the user the inventory and the ordered tasks, and wait for a yes before building. This
is the plan; a missing item here becomes a broken site later.

## Refresh: a newer release of the same major

Run when the upgrade file exists and a newer CMS release of its major is out (rc1 to rc2, or
the last RC to the final release). Work on the same branch.

1. Read the CMS release the file targets now. Find the newest release of the major. If it's
   the same, say so and stop.
2. Run inventory steps 1 to 6 again, with the file's current release as the "current" tag
   and the newer release as the target. Breaking changes between two RCs are rarer but do
   happen. Re-read the docs page too: it's often only finished for the final release.
3. Append what you find to the file as new entries and new unchecked tasks. Don't rewrite or
   untick earlier ones; they're done and committed. Update the file's target release line.
   Don't re-offer step 10's or step 11's list, but re-check each unchecked step 10 task against the newer
   tag: its locked packages, and whether a forced bump changed.
4. Always add a task, ahead of any unchecked step 10 or removal tasks, to move the CMS
   packages, `@umbraco-cms/backoffice`, every shared dependency (step 1 at the newer tag),
   and the package's own pre-release version to the newer release. On the final release,
   that drops the package's pre-release suffix unless the user wants one more pre-release
   first.
5. Show the user the new entries and tasks, wait for a yes, then build them as below.

## Build

Commit the upgrade file on the new branch first, following the project's commit
conventions (`git-workflow`): for example `docs: add upgrade plan for v<major>`, or
`docs: refresh upgrade plan for <release>` on a refresh. Then,
for each unchecked task, in order, follow `feature-build`'s loop with these differences:

- **Build.** Give the `builder` the task text, the matching inventory entries (with their
  docs link or CMS PR), and the CMS release tag to read source at. Tell it to invoke
  `umbraco-cms-source` and `umbraco-docs` for the **target** major, not the current one.
  The same rule `umbraco-package-conventions` sets for public API applies here: if the
  upgrade forces a change to the package's own public API, proxy it with `[Obsolete]` where
  possible, and record it in the file's "Breaking changes for consumers" section when not.
- **Review.** Dispatch `reviewer` as usual, with the inventory entry as the task. No
  `#pragma warning disable` or `<NoWarn>` to silence a removed-API warning, and no skipped or
  weakened tests to get green. Either one is a `FAIL`.
  For a removal task from inventory step 9, give the reviewer the deprecation message that
  scheduled it, so a planned removal isn't flagged as an unproxied public API break. It
  still checks that nothing inside the package, its tests, or its demo site uses the removed
  code.
- **Smoke.** Use the order in `feature-build`'s "Smoke the real entry point" step. Once the
  framework bump task lands, the demo site must start on the target major and the backoffice
  must load with the package's extensions registered. Open every screen the package adds and
  read the browser console: an error from the package fails the smoke, and an "Umbraco
  Backoffice:" deprecation warning with the package as its origin becomes a task. Run the
  scenario for each subsystem the package extends (inventory step 2) once its task lands.
- **Tick and log.** Tick the task in the upgrade file and add its commit SHA to the "Log"
  section. A decision the inventory left open goes in the file's "Decisions" section.

## Finish

When every task is ticked:

1. Run the full test suite on every database provider the project supports.
2. **Smoke an upgrade, not just a fresh install.** Start a demo site on the current major
   with the package installed and some of its data in place. Move that site to the target
   major with the upgraded package. Check the package's migrations run and its data still
   shows, including data a CMS migration rewrote (inventory step 2). If the project has no demo site, say this was skipped in the PR.
   On a refresh, the smoke still starts from the previous major, not from the last RC: that's
   the upgrade users will run.
3. Dispatch one `reviewer` in whole-feature mode over the branch diff, with the upgrade file
   as the design. Fix and re-review until `PASS`, as in `feature-build`'s "Finish".
4. Open the PR with `pr-describe`, or update it if a PR for this upgrade is already open. It
   uses its plain style, since there's no plan folder. Point it at the upgrade file, so the PR
   lists the breaking changes handled, any breaking changes for consumers, and the
   follow-ups.

## Archive

Once the upgrade is done (its PR merged, targeting the final release), move the upgrade file
out of `docs/upgrades/` so that folder holds only live upgrades. From a clean tree on the
line's trunk, follow `feature-close`'s
"Close each plan" steps, with the upgrade file in place of a plan folder:

- The status line goes at the top of the upgrade file itself, under its title.
- Step 2 reads the file's "Decisions" section. Open "Follow-ups" have no lasting home here:
  list them for the user to turn into tracker issues before the move.
- The file moves to `<archive-path>/upgrades/v<major>.md`.

## Rules

- One major per run. A two-major jump is two runs, each ending green. Refreshing to a newer
  release of the same major is a run of its own, on the same branch and file.
- The CMS source at the target tag beats the docs, and both beat memory. Quote the tag or
  page behind every inventory entry.
- Never commit to the current major's line, or to `main`, without asking.
- If a task still fails after `feature-build`'s rethink round, stop and report it with its
  findings. Don't work around a removed API by copying the CMS's old code into the package.

## Hand off

Report: current to target version (and the CMS release, if it's a pre-release), tasks done
and commits, what the upgrade smoke showed, third-party dependencies moved, any breaking
changes for consumers, and the follow-ups. Then the PR link.
