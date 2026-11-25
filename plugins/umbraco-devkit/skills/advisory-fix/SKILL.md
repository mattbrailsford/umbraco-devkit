---
name: advisory-fix
description: >-
  Fixes a confirmed security vulnerability in an Umbraco package from report to published
  advisory, under embargo: checks the issues without changing code, records an embargo so
  the fix can't reach a public remote early, plans and builds the fix on every affected
  version line with the builder and reviewer agents, works out the affected and fixed
  version ranges for the security team, prepares and times the release, and publishes the
  advisory. Follows the project's own security process from `CLAUDE.md`. Use when a
  vulnerability report, security advisory, GHSA or security ticket needs fixing. Owns the
  `## Security process` section of `CLAUDE.md`.
user-invocable: true
argument-hint: <GHSA id or security ticket id, to start or resume>
---

# advisory-fix

A security fix is a normal fix with three extra jobs: nothing about it may become public
before the advisory, the security team needs to know exactly which versions are affected and
which fix them, and the release has to land at an agreed time. This skill does all three, and
follows the project's own security process instead of assuming one.

## Scope

- IN: one advisory, which may hold several related issues, across every supported version
  line it affects. From the confirmed report to the published advisory.
- OUT: deciding whether an untriaged report is a vulnerability (`issue-triage`'s Security
  reports section flags it; the security team confirms it). Dependency CVEs with an upstream
  fix (`dependency-review`). The release pipeline itself, which each project owns.

## Argument

`$ARGUMENTS` is the GHSA id (`GHSA-xxxx-xxxx-xxxx`) or the security team's ticket id. The
advisory's key is its GHSA id whenever there is one, because the key names the private fork.
Given a ticket id, read the ticket (step 1) and look in it for a GHSA id; if there is none,
ask whether a GitHub advisory exists, and without one the ticket id is the key. Record both
ids in the advisory file's header.

With an existing advisory file, resume it at its first unfinished step: `notes.mjs --list`
shows each file's key and the ticket it came from. With nothing, ask for the id. If the user found
the hole themselves and nothing has been reported yet, stop: tell them to report it to the
Security process section's "Report a vulnerability to" address first, and start from what
comes back.

## The security process (`CLAUDE.md`)

This skill owns the `## Security process` section of the project's `CLAUDE.md`. Read it
before anything else, before reading the report or any code. If it, or a line in it, is
missing, stop there: ask for each missing line, one question at a time, with your suggestion,
and write the answers in. Step 1 starts only once the section is complete. Suggest only
what's generic (GitHub's private reporting, the advisory's comments); never guess an
organisation's address, channel, or approver, even one that seems obvious from the package
name. Those come from the user. With no process at all (often a small community package), suggest
GitHub's private vulnerability reporting and repository security advisories as the default.

```markdown
## Security process
- Report a vulnerability to: <email or URL, e.g. security@example.com, or GitHub private vulnerability reporting>
- Reports arrive as: <a GitHub security advisory | a ticket in <tracker>>
- Read with: <MCP server | CLI | paste it>
- Updates go to: <the advisory's comments | an email thread | a private channel per advisory, named <pattern, e.g. team-security-{ticket}>, or (ask each time) | none>
- Security team needs: <what they ask for, e.g. affected and fixed version ranges, release date>
- Approves release: <who says go: a security team, the maintainer>
- Release timing: <how the agreed severity sets whether to fix, which lines, which version and when, e.g. Critical/High: every supported line at once; Low: next minor | the same for every issue>
- Private fork: <GitHub advisory fork | none: share the fix as patch files>
- Advisory published by: <who, and when, e.g. the maintainer once packages ship>
```

`CLAUDE.md` is committed, often to a public repo, so this section describes the process only.
Never write a ticket id, advisory id, channel name, or anything about a specific issue in it.

## Where this writes

- **Owns:** the advisory file, `<git common dir>/devkit-advisories/<key>.md`, made from
  `templates/advisory.md`. It lives inside the repo's `.git` folder: no worktree tracks it, no
  push carries it, every worktree of the checkout sees it, and it survives a `/clear`. Exploit
  detail is allowed here and only here.
- **Through its script only.** Claude Code's file tools won't write inside `.git`, so every
  change goes through `scripts/notes.mjs` in this skill's folder, run from inside the repo.
  Keep each change small: add to or replace one section, never retype the whole file.

  ```bash
  N="node <this skill's folder>/scripts/notes.mjs"
  $N <key>                                        # create it if missing, then print it
  $N <key> --append Log <<'EOF'
  - 25-11-2026: Issue 1 confirmed in DraftsController.
  EOF
  $N <key> --section Versions <<'EOF'
  | Package | Line | Affected | Fixed in |
  ...
  EOF
  $N <key> --write < file                         # last resort: replace it whole
  ```

  Headings match by their first words, case-insensitively, and a missing one is added at the
  end. Each change keeps the previous version as `<key>.md.bak`. Read the file by running
  `$N <key>` again, not with the file tools.
- **Never** writes a plan, change file, or note about the advisory anywhere git tracks, and
  never into project memory.
- `issue-triage`'s Security reports section keeps an unconfirmed report in chat only. Once
  the security team has confirmed it, this file is the one place its details may be kept.

## What stays private

Until the advisory is published, anything another person could read says what changed, never
what was exploitable. That covers commit subjects and bodies, branch names, PR titles and
descriptions, code comments, test names, changelogs, release notes, docs, and chat or email
outside the private update channel. It covers commits on the private fork too, because they
become public as they are when the fix merges.

- **Neutral:** "Check user group access when listing content", "Keep secret settings out of
  deploy exports", branch `v18/hotfix/listing-access`.
- **Not neutral:** "Fix auth bypass in listing endpoint", "Stop leaking API keys", branch
  `v18/security/...`, a test called `Anonymous_user_can_read_drafts`, a comment saying what
  an attacker could do.
- The advisory key, the ticket id, and the reporter never appear in public text either.

The details go in the advisory file and, at publish time, the advisory itself.

## Steps

Record every step's outcome as it finishes with `--append Log`, one dated line each
(DD-MM-YYYY unless the project says otherwise).

### 1. Read the report

Read it from where the Security process says it lives, with the tool it names. If that fails,
ask the user to paste it; don't guess. Find the update channel: when the Updates line gives a
naming pattern, fill in `{ticket}` or `{ghsa}` and, if the chat tool can, check the channel
exists; ask only when there's no pattern, the process says to ask, or the channel isn't
there. Create the advisory file and fill in its header and Issues section: both ids, each
reported issue, the channel, and the severity the security team agreed (ask if the report
doesn't say; it's theirs to set, not yours).

### 2. Check, don't change

Confirm each issue in the code without editing anything: the entry point, the missing or
wrong check, and the versions where the code exists. Look for the same mistake nearby, as
`quick-fix` step 7 does; a sibling found here joins the advisory, flagged as not in the
original report, so the security team hears about it. Record for each issue: confirmed or
not, where, and why. Report back before going further.

### 3. Embargo

Before any branch gets a commit, record the embargo:

```bash
node <this skill's folder>/../../hooks/embargo.mjs add <key> --branch <branch> [--branch <branch>...] [--ticket <ticket id>]
```

Name every fix branch, one per version line, with neutral names. Pass the ticket id too when
the key is the GHSA id: the guard then blocks either id in a commit message, branch name or
PR, and asks before text with words like "bypass" or "XSS" goes out. Treat a block as a
wording mistake to fix, never something to get round. Add a branch the same way
whenever one is created later, release branches included. Show the output of
`embargo.mjs status` to the user. If it says the git pre-push guard isn't installed, say so:
pushes from outside Claude Code aren't checked in this repo.

If the script can't run (no git, no node), stop: give the user the exact `add` command, with
its branch names, to run themselves. Nothing is committed until `embargo.mjs status` shows
the embargo.

With a GHSA key, the only remote allowed is the advisory's private fork, which GitHub names
`<repo>-ghsa-xxxx-xxxx-xxxx`. With a ticket key there is no allowed remote. Only the user
lifts the embargo; never try.

### 4. Plan

Write the plan into the advisory file's Plan section, with every decision in it, and show it
once:

- **Fix:** for each issue, what changes and where, and why this way.
- **Severity:** apply the Security process's Release timing for the agreed severity. Where
  it allows not fixing, ask whether to fix before planning anything else.
- **Lines:** every supported version line the issues reach, unless the Release timing
  narrows them. Build on the newest, then port.
- **Public API:** any change to a public signature follows `umbraco-package-conventions`. A
  security fix ships as a patch, so it can't break anyone.
- **Release:** whether a release already in progress waits for this fix or ships first.
  Ask; the answer changes the fixed version numbers.
- **Versions:** the draft of step 5's table.

Ask the open choices in the same message, each with your recommendation. Wait for a yes on
the whole plan.

### 5. Versions

Work out, for each package the issues reach and each version line:

- **First affected:** find the commit that introduced the flaw (`git log -S`, `git log -L`,
  or blame on the faulty lines), then the earliest release tag that contains it
  (`git tag --contains <commit>`). Read the project's tag format from `git tag` first: one
  tag per release (`v1.2.3`) or per package (`My.Package@1.2.3`). A flaw older than the
  first tag affects every release on that line.
- **Last affected:** the latest released version on the line.
- **Fixed in:** the next patch version on the line, as the release step will number it,
  unless the Release timing says otherwise for this severity (for example, the next minor
  on the newest line). Check it against how the project bumps versions, per package or
  together.
- A line out of support: affected, no fix, said plainly.

Write the table into the advisory file's Versions section, with each range in GitHub's
advisory format so it pastes straight in:

| Package | Line | Affected | Fixed in |
|---|---|---|---|
| My.Package | 17 | `>= 17.0.0, < 17.6.1` | 17.6.1 |
| My.Package | 16 | `>= 16.2.0, <= 16.9.4` | none (out of support) |

Give the security team what the Security process says they need, as a draft for the update
channel (step 8's rules). If a package or issue joins later, rebuild the table and flag that
the security team needs an update.

### 6. Build

On a fix branch per line, cut from that line's trunk with the project's `WorktreeCreate` hook
if it has one, follow `feature-build`'s loop for each fix (build, pre-review checks, review,
smoke, commit), with these differences:

- **Builder and reviewer** get the advisory file's issue and fix sections in place of
  `ARCHITECTURE.md` and `SPEC.md`, and this skill's "What stays private" rules. The reviewer
  checks the fix closes the hole through the real entry point, and that nothing in the
  diff or commit message is not neutral.
- **Tests** prove the hole is closed: each new test fails without the fix. Name them for the
  behavior, as the neutral examples above do.
- **Port** to each other line with `change-backport`'s checks and its apply, build, test and
  review steps, but stop before its push and PR: those go to the private fork (step 7).
- **Log** each commit and what was verified in the advisory file. Tick nothing in any
  tracked file.

### 7. Review

- **Private fork:** push the fix branches to it and open one PR per line there. The embargo
  allows exactly this. The PR descriptions may describe the issue; the fork is private.
- **No private fork:** nothing leaves the machine. Offer the review in the way the Security
  process names, or as patch files for the user to share privately. Write them where git
  never tracks them, one folder per line:
  `git format-patch -o "$(git rev-parse --git-common-dir)/devkit-advisories/<key>-patches/<line>" <base>..<branch>`.
  Log each folder in the advisory file.

An advisory filed on a repo that holds no code (a separate issue tracker repo) has a private
fork with no code in it, and pushing the whole codebase there to review one fix isn't
practical. Treat it as no private fork.

Post a short update to the update channel (step 8's rules) with the PR links or patch files.

### 8. Updates

Every update to the security team or update channel is a draft. Show it, and post only on a
yes, through the tool the Security process names. Updates may describe the issue only when
the channel is private.

### 9. Release

1. **Check the numbers.** Compare the versions the release will produce with step 5's table
   and with what the security team was told. Any difference goes back to them before release.
2. **Agree the time.** Propose the release date the Release timing gives for this severity
   (a fixed weekday, a notice period, a blog post ahead), then ask for the date and time and
   who approves it (the Security process names who).
3. **Draft the advisory.** Write its text into the advisory file's Advisory section, in
   GitHub's advisory fields, and send it to the security team as a draft update (step 8)
   before the release date, whatever else is still open: they may need it early, to request a CVE or plan an
   announcement.
   - **Summary:** one line, what an attacker could do, in which product.
   - **Impact:** who could do it (anonymous, any backoffice user, a user with a given
     permission), to what, and under which setup. Enough for a site owner to judge their
     risk; never the steps to exploit it.
   - **Affected and patched versions:** step 5's table, ranges in GitHub's format.
   - **Workarounds:** a setting or change that closes the hole without upgrading, or "None".
   - **Severity:** the one the security team agreed, with its score if they gave one.
   - **Credit:** the reporter, the way the report names them. Ask how they want to be
     credited if it doesn't say; never guess a GitHub handle.
4. **Prepare locally.** Prepare release branches, changelog and release notes locally, in the
   project's own way, with neutral wording. Add each release branch to the embargo. Draft the
   docs changes the fix needs, with neutral wording, in a local branch of the docs repo.
5. **Lifting is the user's.** Pushing anything public, a release branch to start CI
   included, needs the embargo lifted. Say what lifting early exposes and for how long, then
   ask the user to lift it themselves, in their own terminal, when the approver says go:
   `git embargo lift <key>`. Without that shortcut (the guard wasn't installed), it's
   `git config --remove-section devkit-embargo.<key>`.
6. **Time it.** For each step that must happen at release time (opening the docs PR,
   publishing the advisory), say how it will run and ask:
   - a timer in this session (`CronCreate`), which only fires while the session stays open;
   - a cloud scheduled task (`schedule`), which can only use what's already pushed, so only
     for steps that don't reveal the fix;
   - a checklist for the user to run at that time.

### 10. Publish and tidy

Once the packages are out:

1. Bring the Advisory section up to date with the versions that actually shipped, and hand
   it to whoever the Security process says publishes it. Writing to GitHub's advisory is
   outward-facing: ask first.
2. Open the docs PR, if not scheduled.
3. Offer to delete the fix and release branches, local and remote, and remove their
   worktrees. Ask before each delete.
4. Close the advisory file with a `> **Status:** Published <date>` line, and record any
   lesson that isn't about the vulnerability itself, as `project-retro` does.

## Rules

- One advisory per run. Its file is the only place its details live.
- The embargo goes on before the first commit, and every new fix or release branch joins it.
- Never lift, loosen, or work around the embargo, `--no-verify` included.
- Every outward-facing write needs a yes: an update, a PR outside the private fork, the
  advisory, a docs PR.
- Builder writes code, reviewer gates it, this skill owns the advisory file. Never edit code
  here yourself.

## Hand off

Report the advisory key, the step reached, the version table, and what's waiting on whom.
Name the next command with its argument: `/advisory-fix <key>`.

- **If another skill started this one**, return those and stop. That skill decides what runs
  next.
- **Otherwise**, offer the next step.
