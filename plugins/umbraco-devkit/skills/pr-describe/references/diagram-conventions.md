# Diagram conventions for a PR description

The change outline shows what the PR built with the fewest views that explain it. Each view's
shape is in `diagrams`' `references/text-views.md`; this file says which ones a PR uses and
in what order.

## Pick the views

- **Plan pictures first.** When the plan folder has `diagrams/`, show each one that matches
  what the PR built (see below), then the text views for the detail a picture can't carry.
- **Only views that changed.** Skip any view that doesn't apply. A one-file bug fix might use
  none and just need "Why" and "How to verify."
- **The change form.** Use each view's change form from `text-views.md`: a `diff` against the
  old shape, or the whole block when most of it is new. Read its "Reading rules for every
  view" first: a line that changed but still exists stays a context line, with what changed
  in a trailing comment.
- **Endpoints at summary depth.** The contract depth belongs in `SPEC.md`.

## Picture diagrams — from the plan folder's `diagrams/`

`feature-design` draws SVG diagrams of the flow, call order, statuses, data model or layers.
Show each one that matches what the PR built, under a one-line caption, linked by full URL
pinned to the pushed commit:

```md
How a delivery moves from publish to delivered or dead-lettered.

![Delivery flow](https://github.com/<owner>/<repo>/blob/<sha>/docs/plans/<feature-slug>/diagrams/delivery-flow.svg?raw=true)
```

Don't redraw them here. A picture replaces the text view that tells the same story, per
`text-views.md`'s "Picture or text view".

## Rule of thumb

Tell the story in the order a reader needs it — a data structure or contract usually comes
before the code that consumes it, a table before the query that reads it. All views are
optional; use only the ones that carry weight for this specific PR.
