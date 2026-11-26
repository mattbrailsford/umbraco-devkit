---
name: issue-backlog
description: >-
  Works a tracker's open issues from new to fixed, one stage at a time: triage, maintainer
  decisions, investigation, then fixes. Shows how many issues sit in each state and runs the
  next stage. Use for "work through the backlog" or "what's next on the tracker". For one
  known issue, use `issue-triage`, `investigate-bug` or `issue-resolve`.
user-invocable: true
argument-hint: "[stage to start at: triage | decisions | investigate | fix, optional]"
---

# issue-backlog

The front door for getting a tracker from "a pile of issues" to "fixed." It doesn't triage,
decide, investigate, or fix anything itself. It shows where every open issue stands, picks
the next stage, and hands that stage to the skill that owns it.

## Scope

- IN: count issues by state, suggest the next stage, run it through its owning skill, run
  investigations in parallel and gather their results, apply the tracker updates the user
  approves, start fixes one at a time, keep a run log the user can watch.
- OUT: triage judgments (`issue-triage`), proving a cause (`investigate-bug`), the fix itself
  and its tracker updates (`issue-resolve`), and any tracker write the user hasn't
  approved.

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

## The run log

A run scrolls out of sight in chat. Keep the board and every issue the run touches in one
file the user can keep open beside it.

- **Where.** `RUN.md` in the issues folder `issue-triage` keeps its drafts in (its "The
  drafts file" section), so one preview shows both the run and what's waiting for approval.
  The folder is under git's own folder, so the log is never committed.
- **Start.** Write it as soon as the board is counted, before asking about the first stage.
  If a `RUN.md` from earlier today exists, keep its rows: the run was cut short, by a `/clear`
  or a closed session, and is picking up again. Otherwise start it empty.
- **Keep it current.** Rewrite it after every change, not at the end of a stage: the board
  when it's counted again, a row as each issue gets a result (each investigation as it
  returns, not when the batch ends), and its status once the user approves or skips it.
- **Shape.** The date it started, then:
  - The board, as a table of counts. Link each count to the tracker's own list of those
    issues, when the tracker has a filtered list a link can open. On GitHub that's an issue
    search for open issues with the row's labels, such as
    `https://github.com/<owner>/<repo>/issues?q=is:issue+is:open+label:state/ready`:
    several labels in one row join with commas (`label:state/needs-info,state/blocked`),
    and To triage excludes every state label (`-label:state/ready` for each). The tracker
    link shows every issue with the label, so it can differ from a count that leaves some out.
  - `## Issues this run`: one row per issue, ordered by issue number, so one that opens
    mid-run lands in its place. Issue number and title, stage,
    the result in a few words, the state label it gets, and its status: `drafted`,
    `applied` or `skipped`. A `drafted` status links to that issue's draft
    (`DRAFTS.md#<number>`); drop the link once it's applied or skipped.
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
3. **Needs investigation** → the investigation stage below. It's slower, so it comes after
   the quick stages.
4. **Ready** → the fix stage below. Fixing comes last because every stage above feeds it.
5. **Nothing left** → everything is in progress or waiting on someone else. Say so.

Say which stage is next and why in one line, and run it on the user's yes. When it finishes,
show the board again and pick again, until the user stops or nothing is left to act on.

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
- Never run the next stage without saying what it is and getting a yes. A stage can mean
  dozens of subagents.

## Hand off

Where the run log is, the board, and what's still open: issues in progress, and issues waiting on a reporter or
an upstream fix.
