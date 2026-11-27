---
name: pr-review
description: >-
  Reviews a pull request from outside the core team on an open-source Umbraco package: runs
  the `reviewer` agent, then checks what's unsafe to build locally, security, contribution
  rules, docs, and whether the diff does what it claims. Links the issue the PR fixes, fixes
  small findings itself, and offers to merge, sending a PR back only when its approach is
  wrong; never posts, pushes or merges without a yes. Use for community PRs. For your own task's diff, use `reviewer` through
  `feature-build` or `quick-fix`.
user-invocable: true
argument-hint: <PR number or URL>
---

# Review a contribution

For a pull request filed against an Umbraco package's public repo by someone outside the core
maintainer team. Most packages in this space are open source, so this is a steady trickle, not
an edge case. The diff didn't come from your own `builder`/plan-folder pipeline, so three
things are different from a normal in-house review: you don't know the author's intent beyond
what the PR says, you haven't vetted the code that's about to run on your machine, and the
trust bar for "does this quietly break something" needs to sit higher by default.

This skill doesn't replace `reviewer` — it wraps it. `reviewer` already carries the
Umbraco-aware checklist that matters most here: public API impact, a renamed manifest `alias`,
multi-version/provider parity, layering, and the security skills. This skill adds the handful
of checks that only exist *because* the diff came from outside.

## Scope

- IN: a PR on a package's public repo, opened by someone who isn't a core maintainer. Fetching
  it, reviewing it, linking the issue it fixes, fixing small findings on its branch, drafting a
  review comment, and pushing and merging once the user says yes.
- OUT: a `feature-build` task's own diff (dispatch `reviewer` directly — that's what
  `feature-build`/`quick-fix` already do); merging, approving, or requesting changes without
  you confirming first; rewriting a PR whose approach is wrong (that goes back to the
  contributor); clicking through it on the demo site yourself (`pr-demo`).

## Argument

`$ARGUMENTS` is a PR number or URL. If empty, ask which PR.

## Workflow

1. **Fetch the PR, don't run anything yet.**
   `gh pr view <number> --json title,body,author,baseRefName,headRefName,headRefOid,additions,deletions,files,closingIssuesReferences,reviews,commits`
   and `gh pr diff <number>`. Read the diff before touching your working tree. If a
   maintainer approved it and nothing was pushed since, the review is done: go to step 11.

2. **Scan for anything that would execute on your machine before you build or test.** A
   malicious or careless PR can put code where CI, a build, or a package restore will run it
   automatically. Flag any of these as `Critical` and read them by hand before continuing:
   a changed `.github/workflows/*`, a build script (`.ps1`, `.sh`, `csproj`/`build.cake`
   targets), `NuGet.config` (a changed package source can redirect where packages come from),
   a new or changed `npm`/`package.json` `scripts` entry (`postinstall` runs unattended), or
   any new binary/executable file. None of these block the review outright, but don't run
   `dotnet build`/`npm install` against the PR branch until you've read what they'd execute.

3. **Check out the branch.** `git status` first (per this project's own safety rules — don't
   discard uncommitted work). Then `gh pr checkout <number>`.

4. **Treat the PR's own description as its task.** There's no `PLAN.md` task text for an
   outside contribution — the PR title/body (and the issue it links, if any) is the closest
   equivalent. Read it before judging the diff: `reviewer` needs a task to judge scope against
   in its own step 8, and "what the PR says it does" is that task here.

   **Link the issue it fixes, yourself.** Skip this if `closingIssuesReferences` already
   lists one. Otherwise look for an open issue the PR fixes: any issue it names by number,
   then a tracker search on the words of its title and the area it changes. Never ask the
   contributor to add the link; it's quicker to do it.
   - **A clear match:** the PR names the issue, or describes the same problem the issue
     reports, and fixes all of it. Add the link without asking: append a blank line and
     `Fixes #<issue>` to the PR's description (`gh pr edit <number> --body-file <path>`,
     keeping the body as it was above it). The review comment says so in one line ("I've
     linked this to #12."). If the edit is refused, put the link in the draft for the user
     instead.
   - **Not clear,** or it fixes only part of the issue: don't link. List it for the user
     under the draft ("May fix #12: link it?").

   The link is what makes the merge close the issue. GitHub closes it only when the PR
   targets the repo's default branch; step 11 covers the other case.

5. **Dispatch `reviewer`** (Agent tool, `subagent_type: reviewer`), passing the PR's stated
   intent as the task. With the PR branch already checked out, its own step 1 (`git diff`
   against the base branch) finds the same diff you just scanned. Let it run its full
   workflow — build, test, docs/sibling comparison, consumer-impact, entry-point trace, ghost
   code, multi-version/provider parity, verdict.

6. **Add the checks `reviewer` doesn't know to make for outside code:**
   - **The security skill runs unconditionally.** `reviewer` only reaches for
     `umbraco-security` when the diff visibly touches auth, user input, the Management API,
     or secrets. For a PR from outside the team, load `umbraco-security` yourself regardless
     of what the diff looks like it touches, and whether or not `reviewer` ran. A security
     pass from memory doesn't replace it: the skill holds the Umbraco-specific checks you
     won't think of unprompted. An external diff is a new trust boundary, and "doesn't look
     security-relevant" is exactly the blind spot a deliberately disguised change would aim
     for.
   - **Contribution hygiene.** If the repo has a `CONTRIBUTING.md`, check the PR follows it:
     target branch, commit/PR conventions, sign-off trailer (DCO/CLA) if the repo requires
     one, tests included for new behavior.
   - **Docs flag, no assumed location.** If the diff adds or changes a public feature, flag
     that it probably needs a docs update — but don't assume where. Only Umbraco HQ-owned
     packages keep docs in the UmbracoDocs repo; everyone else keeps docs in their own repo, a
     separate site, or nowhere formal. Say "this looks like it needs a docs update, check
     wherever this project keeps its docs" and leave it there.
   - **Intent match.** Compare the diff against the PR's own stated purpose (and linked issue,
     if any). Flag anything beyond it — an unrelated reformat, a drive-by refactor of a file
     the stated fix never needed to touch — as a `Suggestion` if small and harmless, `Important`
     if it changes behavior outside the stated scope. This isn't `reviewer`'s own scope check
     (step 8 in its workflow), which judges against a plan-folder task; here there is no plan,
     so the PR's own description is the only scope boundary there is.

7. **Check every finding before it reaches the contributor.** A wrong finding on an outside
   PR costs the contributor a round trip and makes the next finding easier to ignore. Do
   this on every PR, however small, and don't check the findings yourself instead: you
   collected them, so you're the wrong one to doubt them. Dispatch one fresh general-purpose
   subagent (Agent tool) on the checked-out branch with every finding from steps 5 and 6.
   Tell it to try to disprove each one by reading the code around the cited file:line and
   beyond the diff: a guard in a base class, attribute or caller, a handler elsewhere that
   already covers it, an API that doesn't behave the way the finding assumes. It returns
   each finding as confirmed, refuted, or unsure, with the evidence. Drop refuted ones, and
   turn unsure ones into a question for the contributor instead of a demand. List what was
   dropped, and why, for the user under the draft, not in it.

8. **Fix it here, unless the approach is wrong.** Sending a PR back costs the contributor a
   round trip and often stalls it for weeks; a small fix costs minutes. Sort the findings
   that survived step 7:
   - **Fix here:** a finding worth fixing whose fix is small and plain. It keeps the PR's
     approach, and the right code is clear: a missing null or empty check, a missing
     translation key, a test for the new behavior, a wrong cache key. A `Suggestion` is
     fixed here only if it's worth the change; otherwise list it for the user, not in the
     draft.
   - **Back to the contributor:** the approach itself is wrong, such as the wrong extension
     point, a design the project doesn't want, or a fix that means rewriting most of the
     diff. Also any unsure finding from step 7, since only they can answer it. Unsure which
     side a finding falls on: ask the user.
   - **Never fixed here:** a PR step 2 found trying to run something it shouldn't. It goes
     back, or the user closes it.

   If anything goes back, fix nothing yet: one comment covers it all, and a new approach may
   change the rest. Otherwise dispatch `builder` (Agent tool, `subagent_type: builder`) on
   the checked-out PR branch, with the fix-here findings as its task, told to commit
   following `git-workflow` and not push. Then dispatch `reviewer` again on the branch's whole
   diff against its base. A FAIL goes back to `builder`, at most twice; after that the
   findings go back to the contributor. Nothing is pushed before the user's yes in step 10.

9. **Draft the review, don't post it yet.** Combine `reviewer`'s verdict and the findings
   that survived step 7 into one comment. Before the first finding, give one line with the
   verdict and the count per tier, such as `Changes needed: 1 Important, 2 Suggestions`, or
   `Fixed here: 1 Important` when step 8 fixed them; with nothing to fix, say so in those
   words. For each fix made here, say in a line what changed and why, so the contributor
   learns from it; never ask them to make it. Then the findings, grouped the same way
   `reviewer` tiers them (Critical / Important / Suggestion / Pre-existing). Pre-existing
   ones are for the maintainer, so say plainly the contributor doesn't need to fix them.
   Write it following `plain-writing` — a contributor who doesn't know this codebase needs to be able to act on
   it. Say what's blocking and what's a nice-to-have; don't bury a `Critical` finding in a
   wall of Suggestions.

10. **Show the draft and ask before posting.** A PR comment on a public repo is visible to the
   contributor and anyone else watching the repo — confirm with the user first, every time.
   Once confirmed, post with `gh pr review <number> --comment --body-file <path>` for a plain
   comment, or `--request-changes`/`--approve` instead of `--comment` only if the user
   explicitly wants the review state set, not just a comment left. Never pass `--approve`
   without the user having said so. When nothing goes back to the contributor and step 11's
   checks pass, make it one question: approve and merge, approve only, or comment only. With
   fixes made in step 8, the choices are push the fixes, approve and merge; push the fixes
   only; or send the findings back to the contributor instead. End the reply with that question,
   its choices as a short list, after the commands each choice would run.

   **Pushing the fixes.** Push to the PR's branch with a plain `git push` from the branch
   `gh pr checkout` set up; never force-push over the contributor's commits. That works only
   when the PR allows maintainer edits (`maintainerCanModify`). When it doesn't, push the
   branch to this repo instead, open a PR from it that keeps the contributor's commits as
   theirs, and close theirs with a thank-you that links the new one, all as part of the same
   yes. Wait for the checks on the pushed commit (`gh pr checks <number> --watch`) before
   step 11.

   Same sanity rules as `git-workflow`: never `--no-verify`, never force-push, re-check the
   diff for secrets before anything is staged locally.

11. **Merge, on a yes.** Offer it only when all of these hold; otherwise say which one
    doesn't, and stop:
    - Nothing `Critical` or `Important` is left from the review.
    - `gh pr checks <number>` passes, and `gh pr view <number> --json mergeable` says
      `MERGEABLE`.
    - The PR's `headRefOid` is the commit that was reviewed, or the fix commit `reviewer`
      passed in step 8. Any other push since means review again.

    Ask every time: a merge lands on a shared branch. Use the merge method the repo already
    uses (look at how recent PRs were merged, among the methods it allows):
    `gh pr merge <number> --squash`, `--merge` or `--rebase`. Never `--admin`; a required
    check or review is the repo's rule, not this skill's to skip. If the PR targets a branch
    other than the default, GitHub doesn't close its linked issues, so close each one with a
    one-line comment naming the PR, as part of the same yes. Then switch back to the branch
    you were on before step 3.

## Hand off

One line: the PR, the verdict (`reviewer`'s tier plus anything step 6 added), what was fixed
here, the issue it was linked to, and whether the comment was posted and the PR merged, or what's still
waiting on confirmation.
