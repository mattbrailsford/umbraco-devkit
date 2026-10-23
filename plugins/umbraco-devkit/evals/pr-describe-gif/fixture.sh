#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'MD'
# Umbraco.Community.Gallery

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`, and a
branch named after the slug.
MD
P=docs/plans/gallery-sorting
mkdir -p src/client/gallery "$P/screenshots"
cat > "$P/README.md" <<'MD'
# Gallery sorting

1. [x] [BRIEF.md](./BRIEF.md) — editors can reorder gallery items
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — drag to sort in the gallery workspace view
3. [x] [SPEC.md](./SPEC.md) — drag an item; order saves on Save
4. [x] [STORIES.md](./STORIES.md) — one story
5. [x] [PLAN.md](./PLAN.md) — two tasks
6. [x] [BUILD-LOG.md](./BUILD-LOG.md) — two tasks, two commits
MD
cat > "$P/BRIEF.md" <<'MD'
# Gallery sorting: brief

Editors can only change the order of gallery items by deleting and re-adding them.
MD
cat > "$P/ARCHITECTURE.md" <<'MD'
# Gallery sorting: architecture

- `gallery-items-view` uses `UmbSorterController` to let editors drag items.
- The new order is written to the property value; the existing save path stores it.
MD
cat > "$P/SPEC.md" <<'MD'
# Gallery sorting: spec

- An editor drags a gallery item to a new place in the list.
- The new order is kept when the editor clicks Save.

## Frontend components
`gallery-items-view` (changed).
MD
echo "# Gallery sorting: stories"$'\n\n'"1. Reorder gallery items by dragging." > "$P/STORIES.md"
cat > "$P/PLAN.md" <<'MD'
# Gallery sorting: plan

- [x] Add `UmbSorterController` to `gallery-items-view`.
- [x] Write the new order to the property value.
MD
echo "# Gallery sorting: decision log" > "$P/DECISION-LOG.md"
cat > "$P/BUILD-LOG.md" <<'MD'
# Gallery sorting: build log

- Task 1 — `1a2b3c4` — drag to sort in the gallery items view. Screenshot:
  [gallery-items.png](./screenshots/gallery-items.png) (before:
  [gallery-items-before.png](./screenshots/gallery-items-before.png)). Click path: Content › any Gallery page › Items tab.
- Task 2 — `5d6e7f8` — order saved through the existing save path; e2e test reorders and saves.
MD
# Placeholder image bytes; the skill links them, it doesn't read them.
printf 'PNG' > "$P/screenshots/gallery-items.png"
printf 'PNG' > "$P/screenshots/gallery-items-before.png"
printf 'GIF89a' > "$P/screenshots/gallery-items-reorder.gif"
cat > src/client/gallery/gallery-items-view.element.ts <<'TS'
import { html, customElement, property, repeat } from '@umbraco-cms/backoffice/external/lit';
import { UmbLitElement } from '@umbraco-cms/backoffice/lit-element';

@customElement('gallery-items-view')
export class GalleryItemsViewElement extends UmbLitElement {
  @property({ type: Array }) items: Array<{ key: string; name: string }> = [];

  override render() {
    return html`<ul>${repeat(this.items, (i) => i.key, (i) => html`<li>${i.name}</li>`)}</ul>`;
  }
}
TS
git add -A && git commit -qm "docs: add plan folder for gallery-sorting"

# ---- the feature branch's changes ----
cat > src/client/gallery/gallery-items-view.element.ts <<'TS'
import { html, customElement, property, repeat } from '@umbraco-cms/backoffice/external/lit';
import { UmbLitElement } from '@umbraco-cms/backoffice/lit-element';
import { UmbSorterController } from '@umbraco-cms/backoffice/sorter';

type Item = { key: string; name: string };

@customElement('gallery-items-view')
export class GalleryItemsViewElement extends UmbLitElement {
  @property({ type: Array }) items: Array<Item> = [];

  #sorter = new UmbSorterController<Item>(this, {
    getUniqueOfElement: (el) => el.dataset.key!,
    getUniqueOfModel: (m) => m.key,
    identifier: 'gallery-items',
    itemSelector: 'li',
    containerSelector: 'ul',
    onChange: ({ model }) => {
      this.items = model;
      this.dispatchEvent(new CustomEvent('change'));
    },
  });

  override updated() {
    this.#sorter.setModel(this.items);
  }

  override render() {
    return html`<ul>${repeat(this.items, (i) => i.key, (i) => html`<li data-key=${i.key}>${i.name}</li>`)}</ul>`;
  }
}
TS
git add -A && git diff --cached > CHANGE.diff && git reset -q --hard
cat > COMMITS.txt <<'TXT'
5d6e7f8 feat(gallery-sorting): save the new order
1a2b3c4 feat(gallery-sorting): drag to sort gallery items
TXT
