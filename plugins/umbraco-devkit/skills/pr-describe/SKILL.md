---
name: pr-describe
description: >-
  Writes or updates a pull request description: when the feature has a plan folder, the
  choices made without the user first, then screenshots and a diagram-based outline;
  otherwise a summary, why, how to verify, and risks.
  Use whenever a PR is opened or updated.
user-invocable: true
argument-hint: [PR number | leave blank for the current branch]
---

# Describe a pull request

`git-workflow` never writes a PR body by hand — it always runs this skill instead, for every
PR. This skill decides, every time, which of its two styles fits: a diagram-based outline for a
feature-sized change, or a plain summary for everything else.

This skill only composes the description. Branch/push/PR-creation mechanics, force-push and
secret-scanning sanity rules, and the always-ask-before-touching-main rule all stay owned by
`git-workflow` — read that skill's "Pull requests" and "Sanity rules" sections and follow them
as-is; don't restate them here.

## Workflow

1. **Check for a plan folder.** Does `docs/plans/<feature-slug>/` exist for the current branch
   (the feature-* pipeline ran for this feature)? This decides which style you write in step 4 — a
   `quick-fix` or trunk-based commit won't have one, and that's expected, not an error.

2. **Gather context.**
   - Resolve `<base>` first, using `git-workflow`'s "Resolving the base branch" (branch
     prefix, remote existence check, and the stacked-PR check). A wrong base here means the
     diff below includes commits that were never really part of this PR.
   - Plan folder found: read `BRIEF.md`, `ARCHITECTURE.md`/`SPEC.md`, and `PLAN.md` for the
     "why." Then invoke `decision-review` (via the Skill tool) — always, not only if it
     happens to have already run — and use its groups as-is for step 4's "Your call", "Must
     fix" and "Checked and fine". The PR is the one checkpoint a fully autonomous run is guaranteed to get
     a human look at, so this step never skips it: don't fall back to reading `DECISION-LOG.md`
     by hand and don't re-derive the list yourself.
   - No plan folder: read the branch's commit messages instead — there's no separate plan
     artifact to draw on, and `decision-review` needs a plan folder to run against.
   - Either way, read the full diff against the resolved base (`git diff <base>...HEAD`, or
     `gh pr diff <number>` if a PR already exists) — enough of it, and enough surrounding code,
     to explain behavior and ownership, not just line counts.

3. **Find or create the PR.**
   - `gh pr view --json url,number,title,state,baseRefName,headRefName` on the current branch.
   - No PR yet: carry on and write the description first. Step 5 opens the PR with it, using
     `git-workflow`'s "Pull requests" section for the push, title and base branch. Don't
     duplicate those rules here.

4. **Write the description**, in the style step 1 decided. Either way, a stacked PR (step 2)
   opens with `Stacked on #<parent-pr-number>.` ahead of everything else — the template's
   placeholder for it is omitted entirely when the PR isn't stacked.
   - **Plan folder found** — use `templates/pr-description.md`. Sections in this order, so
     a reviewer can stop once they've read what needs them:
     - **Your call** — first, straight after the header line, in a GitHub `> [!IMPORTANT]`
       callout. Every Your call item from `decision-review`, no exceptions; omit the whole
       callout when there are none. It opens with a bold count ("**4 choices were made
       without you.** Please check each one."), then one table row per item, in
       `decision-review`'s order: number, Type, Plan said, Built, Options. Built links to its
       line. Options sit one per line (`<br>` between them), the recommended one first, in
       bold, marked *(recommended)*. Under the table, for each UI item whose screen has a
       mockup in the plan folder's `mockups/`, a two-column "Mockup | Built" table headed
       with the item's number. Look in `mockups/` yourself; don't wait for `decision-review`
       to name the file. Every line
       of the callout, tables included, starts with `> `.
     - **Must fix** — only when `decision-review` returned Must fix items; omit it otherwise.
       A `> [!CAUTION]` callout straight after Your call, one linked line per item.
     - **Why the change** — exactly one sentence.
     - **What it looks like** — only when the PR adds or changes backoffice UI; omit the
       whole section otherwise. In this order:
       - **Where to find it**: the click path through the backoffice to each new or changed
         screen, from its `BUILD-LOG.md` entry ("Settings › Webhooks › any webhook ›
         Deliveries tab").
       - **Who can see it**: the section, user group or permission that decides access, read
         from the manifest `conditions` and the Management API authorization policy. "Anyone
         with access to the Settings section" beats quoting the condition alias.
       - **Screenshots** from the plan folder's `screenshots/`: the built screen for a new
         one; a two-column table with `<screen>-before.png` and `<screen>.png` for a changed
         one. No screenshots on disk means no screenshots in the PR. Never stand a mockup in
         for the built screen; a mockup appears only in Your call, beside the built screen.
       - **GIFs**: each `<screen>-<action>.gif` in `screenshots/` goes straight under its
         screen's screenshot, after a one-line caption saying what it shows ("Dragging a
         gallery item to the top"). A `-before.gif` pairs with its GIF in the same
         two-column table. A GIF never stands in for the screenshot; no GIF on disk, no GIF
         in the PR.
     - **How to verify** — numbered steps a reviewer can follow on the demo site, each with
       what they should see. Take them from `SPEC.md` and the click paths in `BUILD-LOG.md`;
       include an access check when the spec limits who can use the feature.
     - **Good to know** — only for something the reviewer needs before approving that isn't
       a choice: a planned migration, a compatibility limit, a deliberate omission from the
       plan. One line each. Omit the section when there's nothing; never restate the outline
       or the diff.
     - **Change outline** — the smallest set of diagrams that explains the implementation. See
       `references/diagram-conventions.md` for which shape fits which kind of change and how to
       draw it. Only include a view that actually changed; skip the rest. Order them the way a
       reader would want the story told (a data structure or contract usually comes before the
       code that uses it), not in a fixed sequence. Read that file's "Reading rules for every
       view" before drawing: a step or line that changed but still exists stays a context
       line, with what changed in a trailing comment, never a `-` line and a reworded `+`.
     - **Picture diagrams first.** When the plan folder has `diagrams/`, lead the outline with
       the ones that show what this PR built, each under a one-line caption and linked by
       full URL like the screenshots. Then the text views for detail a picture can't carry.
       A diagram that no longer matches the code stays out; never describe a design the PR
       didn't build.
     - Prefer a `diff` block for a change to an existing shape; show the whole thing only when
       most of it is new or the diff notation would obscure ownership or order.
     - **Checked and fine** — last, folded in a `<details>` block whose summary gives the
       count ("Checked and fine (2)"). One line per item. Omit it when there are none.
     - Links in a PR body (images, and lines of code) must be full URLs: a relative path
       breaks. Use `https://github.com/<owner>/<repo>/blob/<sha>/<path>`, adding `?raw=true`
       for an image and `#L<line>` for a line of code, with `<owner>/<repo>` from
       `gh repo view --json nameWithOwner` and `<sha>` the pushed commit that contains the
       file (`git rev-parse HEAD` after pushing). Pinning to a commit keeps the link working
       after the branch is deleted.
   - **No plan folder** — use `templates/pr-plain.md`: Summary, Why, How to verify, Risk /
     rollback. A diagram-heavy outline on a five-line fix is noise, not help.
   - Either way, write it following `plain-writing`: one person explaining a change to
     another, plain language, no jargon that isn't already in the codebase.

5. **Save and publish.**
   - Plan folder found: save the draft to `docs/plans/<feature-slug>/PR-DESCRIPTION.md` first —
     this skill owns that file, the same way `feature-build` owns `BUILD-LOG.md`. Then
     `gh pr edit <number> --body-file docs/plans/<feature-slug>/PR-DESCRIPTION.md`.
   - No plan folder: save the draft to a temporary file outside the repo, then
     `gh pr edit <number> --body-file <that file>`.
   - No PR yet (either case): open it with `gh pr create --body-file <the saved draft>`,
     following `git-workflow`'s "Pull requests" section, instead of `gh pr edit`. Always
     `--body-file`, never `--body`.
   - Confirm the update succeeded.

6. **Report back**, briefly: the PR URL, the saved description's path (if any), and a short
   list of changed files. Nothing else — the PR itself carries the full description.

## Sanity rules

Inherited from `git-workflow`, not restated: no force-push, no `--no-verify`, re-check the diff
for secrets before it goes anywhere, and stop to ask before running `git commit`/`git merge`
straight against the default branch or a `support/*` branch.
