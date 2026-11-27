---
name: issue-backlog
description: >-
  Works a tracker's open issues and community pull requests from new to closed or merged, one
  stage at a time: triage, maintainer decisions, community PRs, investigation, then fixes.
  Shows how many sit in each state and runs the next stage. Use for "work through the
  backlog", "what's next on the tracker" or "get the community PRs merged". For one known
  issue, use `issue-triage`, `investigate-bug` or `issue-resolve`; for one PR, `pr-review`.
user-invocable: true
argument-hint: "[stage to start at: triage | decisions | prs | investigate | fix, optional]"
---

# issue-backlog

The front door for getting a tracker from "a pile of issues and PRs" to "fixed and merged."
It doesn't triage, decide, review, investigate, or fix anything itself. It shows where every
open issue and community PR stands, picks the next stage, and hands that stage to the skill
that owns it.

## Scope

- IN: count issues by state and community PRs by review state, suggest the next stage, run
  it through its owning skill, run investigations in parallel and gather their results,
  apply the tracker updates the user approves, start PR reviews and fixes one at a time,
  keep a run log the user can watch.
- OUT: triage judgments (`issue-triage`), reviewing, linking and merging a PR (`pr-review`),
  proving a cause (`investigate-bug`), the fix itself and its tracker updates
  (`issue-resolve`), and any tracker write the user hasn't approved.

## Preflight

1. Read `CLAUDE.md`'s `## Issue tracker` section. If it's missing, run `issue-triage` first;
   it owns that setup.
2. Use `issue-triage`'s State labels for the label names and what each one means.

## The board

Count open issues in each of these, and show the counts:

| Row | What it holds |
|---|---|
| To triage | No state label, plus anything `issue-triage`'s no-argument run would pick up again (a reporter reply, a needs-info timeout, a closed blocker) |
| Needs decision | `state/needs-decision` |
| Needs investigation | `state/needs-investigation` |
| Waiting | `state/needs-info` and `state/blocked` not yet due for another look |
| Ready | `state/ready` |
| In progress | `state/in-progress` |
| PRs to review | Community PRs with no maintainer review since their newest commit |
| PRs to merge | Community PRs a maintainer approved, with no commit since |
| PRs waiting | Drafts, and community PRs a maintainer asked to change, with no commit since |

A community PR is an open PR whose author is outside the team and isn't a bot. On GitHub,
`gh pr list` doesn't give the author's role, so read it from
`gh api repos/<owner>/<repo>/pulls --paginate`: outside means `author_association` is not
`OWNER`, `MEMBER` or `COLLABORATOR`, and `user.type` is not `Bot`. Bot PRs, such as
Dependabot's, belong to `dependency-review`. A maintainer's review is a review by anyone with
one of those three roles; compare the newest one's time with the PR's newest commit.

## The run log

A run scrolls out of sight in chat. Keep the board and every issue the run touches in one
file the user can keep open beside it.

- **Where.** `RUN.md` in the issues folder `issue-triage` keeps its drafts in (its "The
  drafts file" section), so one preview shows both the run and what's waiting for approval.
  Git ignores that folder, so the log is never committed.
- **Start.** Write it as soon as the board is counted, before asking about the first stage.
  If a `RUN.md` from earlier today exists, keep its rows: the run was cut short, by a `/clear`
  or a closed session, and is picking up again. Otherwise start it empty.
- **Keep it current.** Rewrite it after every change, not at the end of a stage: the board
  when it's counted again, a row as each issue gets a result (each investigation as it
  returns, not when the batch ends), and its status once the user approves or skips it. A
  PR's row changes at each step of its review, not only when the review ends.
- **Shape.** The date it started, then:
  - The board, as a table of counts. Link each count to the tracker's own list of those
    issues, when the tracker has a filtered list a link can open. On GitHub that's an issue
    search for open issues with the row's labels, such as
    `https://github.com/<owner>/<repo>/issues?q=is:issue+is:open+label:state/ready`:
    several labels in one row join with commas (`label:state/needs-info,state/blocked`),
    and To triage excludes every state label (`-label:state/ready` for each). A PR row links
    to the open PR list (`https://github.com/<owner>/<repo>/pulls`). The tracker
    link shows every issue with the label, so it can differ from a count that leaves some out.
  - `## Issues this run`: one row per issue, ordered by issue number, so one that opens
    mid-run lands in its place. Issue number, linked to the issue on the tracker, and title, stage,
    the result in a few words, the state label it gets, and its status: `drafted`,
    `applied` or `skipped`. A `drafted` status links to that issue's draft
    (`DRAFTS.md#<number>`); drop the link once it's applied or skipped.
  - `## PRs this run`: one row per community PR the run touches, ordered by PR number. PR
    number, linked to the PR, and title, the issue it fixes (linked, or "none"), what was
    fixed here in a few words (or "nothing"), and its status: `reviewing`, `waiting on you`,
    `sent back`, `merged` or `skipped`. A PR that's pushed and approved but can't merge yet
    (a check failed) says so in place of a status.
  - `## Waiting on you`: questions the user hasn't answered yet, and a link to
    `DRAFTS.md` while it holds updates waiting for approval, or "Nothing."
- **Security reports.** A flagged issue gets its number and "security report" only, never
  the title or details, as `issue-triage`'s Security reports section says.
- **Show it.** After the first write, offer to open the issues folder with
  `markdown-preview`, scoped to the folder, as its "Offering a preview" section says. Give
  the file's path too, for an editor. The page refreshes on each write.

The tracker's labels stay the record. The log only shows this run's progress; losing it
loses nothing.

## Pick the next stage

The first row with anything in it, in this order, unless the argument names a stage:

1. **To triage** → invoke `issue-triage` (Skill tool) with no argument. Triage goes first
   because it's quick and it feeds every other row.
2. **Needs decision** → invoke `issue-triage` with `decisions`. It's quick, and it needs the
   user, who is here now.
3. **PRs to review or merge** → the community PR stage below. A contributor waiting on a
   reply is the costliest wait on the board, and their fix is already written.
4. **Needs investigation** → the investigation stage below. It's slower, so it comes after
   the quick stages.
5. **Ready** → the fix stage below. Fixing comes last because every stage above feeds it.
6. **Nothing left** → everything is in progress or waiting on someone else. Say so.

Say which stage is next and why in one line, and run it on the user's yes. When it finishes,
show the board again and pick again, until the user stops or nothing is left to act on.

## The community PR stage

1. **Order the queue.** PRs to merge first: they need only a yes. Then PRs to review, those
   that fix an open issue first, since one merge clears both, then the one whose contributor
   has waited longest. Show the order; the user can reorder it or pick a few.
2. **Invoke `pr-review`** (Skill tool) with the first PR's number. One at a time: it checks
   the PR out in this working tree. It reviews, links the issue the PR fixes, fixes small
   findings itself, drafts the review for the user's yes, and offers to merge. A PR goes back
   to its contributor only when its approach is wrong.
3. **Record it** in the run log's PR table as the review goes: `reviewing` when it starts,
   the issue once it's linked, what was fixed here once `reviewer` passes it, `waiting on
   you` with the question under "Waiting on you", then the outcome. A merge that closes an
   issue updates that issue's row too.
4. When `pr-review` hands back, show the board again and offer the next PR. A PR waiting on
   its contributor leaves the queue; it comes back as a PR to review once they push.

## The investigation stage

1. **Order the queue.** Sort `state/needs-investigation` issues by how bad the bug is (data
   loss or a security-adjacent fault, then a crash or a broken screen, then something
   cosmetic), then by demand (duplicates and reactions), then oldest first. Show the order;
   the user can reorder it or pick a few.
2. **Check parallel is safe.** Investigations run in parallel only when the demo site, if
   there is one, can run in several worktrees at once:
   - Its `.csproj` references `Umbraco.Community.WorktreeDevPort`, so each worktree gets its
     own port. If it doesn't, suggest `project-init`'s "Demo site ports" step.
   - Its database lives inside the worktree (such as SQLite under the site folder), not on a
     shared server. A shared database would mix one investigation's data into another's.

   If either fails, run them one at a time instead: invoke `investigate-bug` in this session
   for each issue, in order.
3. **Dispatch.** Up to three at a time, unless the user asks for a different number. Each
   one is an Agent tool call with `isolation: "worktree"`, told to invoke `investigate-bug`
   (Skill tool) with the issue ID and `--unattended`. Send a batch as parallel calls in one message.
4. **Gather.** Pull any security flag into its own list, handled as `issue-triage`'s
   Security reports section says. Draft the rest into `issue-triage`'s drafts file, as its
   "The drafts file" section says: issue, outcome (`state/ready`, `state/needs-info`,
   `state/blocked`, or a close), the cause in one line, and the drafted comment.
5. **Apply** exactly the updates the user approves, as that section says.

## The fix stage

1. Sort the `state/ready` issues the same way as the investigation queue, and show the order.
   The user can pick a different one.
2. Invoke `issue-resolve` (Skill tool) for the first one. One at a time: a fix leaves real changes for the user to review, so it
   never runs in parallel.
3. When `issue-resolve` hands back, show the board again and offer the next ready issue.
   Count the issue as cleared only once it closes, and name any issues it split off, so the
   board shows the net change.

## Rules

- Never write to the tracker without the user's yes, as `issue-triage`'s Rules say.
- Never fix anything itself. Ready issues go to `issue-resolve`, one at a time.
- Never review or merge a PR itself. Community PRs go to `pr-review`, one at a time.
- Never run the next stage without saying what it is and getting a yes. A stage can mean
  dozens of subagents.

## Hand off

Where the run log is, the board, and what's still open: issues in progress, issues waiting on
a reporter or an upstream fix, and PRs waiting on their contributor.
