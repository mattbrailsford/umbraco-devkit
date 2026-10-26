---
name: plain-writing
description: >-
  How to write anything a person reads: README sections and docs pages, upgrade and release
  notes, changelogs, issue and PR comments, PR descriptions, plan files, reviews and triage
  notes. Lead with the point, what needs the reader first, plain words, concise without
  losing detail, a picture in place of a long explanation, and a layout that reads on a
  phone. Use whenever you write or revise prose for a human reader, in a file or in a
  reply. Not for code comments, commit messages or executable
  specs.

---

# Plain writing

## *Why*

Reading is where a person spends most of their time in this pipeline. Every plan file, PR
description and review gets read at least once, often several times, and usually by someone
switching in from other work. A document that takes twice as long to read costs that time on
every read. A document that's short but vague costs more: the reader has to go and find what
it left out.

The goal is the shortest text that still leaves the reader knowing everything they need.

## Lead with the point

- Start each document, section and bullet with the thing the reader needs: the answer, the
  decision, the change. Background and reasons come after, if at all.
- A section's first sentence should make sense on its own to someone who reads nothing else.
- No preamble ("This document describes..."), no restating the request, no closing summary
  that repeats what's above it.

## What needs the reader goes first

Anything the reader has to act on comes before everything else in the document: a guess
they should check, a choice made without them, a question only they can answer, something
broken. Put it in one list straight after the opening line, so a reader who stops there has
done their part.

This is for documents whose reader decides: a plan, a PR, a proposal, a review. A document
published for people to use (a docs page, a README, release notes) has no such list. Its
readers can't confirm your guesses; the person who asked for it can. Raise those points with
them in your reply instead, and leave the published text free of them.

- One numbered item per guess or choice. The guess itself, then a second line starting
  *If not:* with what changes if it's wrong. A question with no sensible guess says so and
  gives the options.
- Open the list with a count in bold, "**2 guesses need your OK.**", inside a
  `> [!IMPORTANT]` callout.
- End the guess's last line with a backslash. In a Markdown file GitHub joins a plain line
  break into one line, so without it *If not:* runs on after the guess:

  ```md
  > [!IMPORTANT]
  > **2 guesses need your OK.**
  >
  > 1. Up to 10,000 rows per file.\
  >    *If not:* a higher limit needs a background job.
  > 2. A row whose source already exists is skipped.\
  >    *If not:* overwrite it, or let the editor choose.
  ```
- Nothing scattered: a guess sits only in this list, not also in the section it's about.
  Once the reader agrees, it moves into its section as a plain fact and leaves the list.
- Nothing to check: leave the list out. Don't write "nothing needs you".

## Plain words, short sentences

- Write the way you'd explain it to a smart colleague from a different team. Short sentences,
  common words, active voice ("the builder writes X", not "X is written").
- Prefer the everyday word: "use" not "utilize", "check" not "validate against", "before" not
  "prior to".
- A technical term is fine when it's the real name of the thing (a class, an extension point,
  a UUI element), but explain it the first time if a non-specialist reader would stumble:
  "a `uui-ref-node` (a row showing a linked item)".
- Don't invent labels or acronyms a reader has to learn just to follow this one document.
- One idea per sentence, one topic per bullet.

## Concise is not vague

Cutting words must never cut information. Keep:

- **Names**: the actual class, route, property, setting or screen, not "the relevant service".
- **Numbers**: limits, sizes, counts, versions, timeouts, not "a reasonable number".
- **Conditions**: when something applies and when it doesn't, not "in some cases".
- **The why** behind a decision that someone might later want to undo.

What to cut instead: filler words, hedging ("it might be worth considering"), repeated points,
explanations of things the reader already knows, and anything the document's own structure
already says (a heading doesn't need a sentence repeating it).

## Let pictures carry what they show

A picture is faster to read than the paragraph it replaces. When text would explain how
parts connect, the order things run in, the states something moves through, or what a
screen looks like before and after, show it instead: a diagram (follow `diagrams`), a
screenshot or a mockup. Keep only the text the picture can't carry, and keep a picture only
when it replaces text; one that repeats a short list is just more to read.

Under a diagram, don't retell its path step by step ("it picks the row, marks it Sending,
then..."). Write what the boxes and arrows can't hold: timings, limits, formulas, who runs
it, what the reader must do. Those details can follow the diagram's order without
repeating its moves.

When a document includes a screenshot, mockup, table or diagram, the text doesn't describe what
the reader can already see in it: the layout, the labels, the column names, the order of
things, the colours. The text covers only what the picture can't show:

- behaviour over time: what happens on click, save, failure, reload
- rules and limits: validation, permissions, what's hidden from whom
- where the data comes from and when it updates
- the states the picture doesn't show: empty, loading, error

For a screen in `SPEC.md`, that usually means the screenshot plus a short list of behaviours,
not a paragraph walking through the screen.

## Shape for scanning

Markdown means GitHub Flavored Markdown, since GitHub is where these documents are read. Use
its features where they save reading: a `> [!IMPORTANT]` callout for what needs the reader,
`> [!CAUTION]` for something broken, `- [ ]` task lists for steps someone ticks off, and
`<details>` to fold detail most readers skip.

- Use a list when items are parallel (options, steps, rules). Use prose when ideas build on
  each other.
- Headings should say what's in the section ("Data model", "What happens on save"), not be
  clever.
- Bold sparingly, for the one phrase per section a skimming reader must not miss. In a list
  of choices or rules, that's the item's name: "**Server-side parsing**, not in the
  browser. One set of checks for the API and the UI."

## Fit a narrow screen

Many readers open a PR, plan or issue on a phone, and GitHub draws Markdown in a narrow
column even on a big screen. A wide table there is a row of squashed cells you have to
scroll sideways through.

- **A table only when every cell is short**: a few words, a name, a number, an image. At most
  one column may hold a sentence, and keep to four columns or fewer.
- **Anything longer becomes a list** with the item's name in bold at the start of the line.
  Two or three facts about one thing become a short block: the name in bold, then each fact
  on its own line.
- **Long values never go in a cell.** A route, a JSON shape, a status code with its body:
  give each its own line under a bold heading line, such as the route, with one status
  code per bullet under it.
- **Check it at phone width** (about 400px). Nothing but a code block or a diagram should
  need sideways scrolling.

## Files written mainly for skills

Some files are read mostly by other skills and only checked by a person: a plan's stories,
its task list, a build log. In those, completeness comes before length, and a skill may
repeat a fact another file owns when it needs it in place (stories restate the spec's rules
as criteria). The rest of this skill still applies: plain words, GitHub Flavored Markdown,
narrow tables. Give a long one a short index or overview at the top, so the person checking
it can see its shape without reading it all.

## One fact, one place

When several documents are read together (a plan folder, a PR and its plan), each fact lives
in the one document that owns it. The others point to it by name ("shapes in SPEC") instead
of saying it again. Two copies cost two reads, and they drift apart when one is edited.

## Before handing it over

Read it once as the reader, then check:

1. Could someone act on this without asking a follow-up question? If not, something specific
   is missing.
2. Is there a sentence that, deleted, would lose nothing? Delete it.
3. Is there a term a non-specialist wouldn't know, used without a short explanation?
4. Does any text describe what a picture or table right next to it already shows?
5. Is there a paragraph explaining a flow, an order or a set of states that a diagram would
   replace?
6. Does anything the reader must act on sit below the opening list, or outside it?
7. Would any table need sideways scrolling on a phone?
8. Does this document repeat a fact another document in the set owns?
