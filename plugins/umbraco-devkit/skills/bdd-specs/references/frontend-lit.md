# BDD specs — Frontend: Lit + TypeScript

**Detect and match the project's actual test framework — don't import a new one to follow this
skill.** Web Test Runner + `@open-wc/testing` is shown as the default because it's the
standard, browser-based way to test real custom elements (Lit components render into actual
shadow DOM, which a DOM-shimmed runner can't always faithfully reproduce); Vitest with a
browser-mode or DOM environment is equally valid if the project already uses it. Either way,
this is component/unit-level specs — Playwright-driven end-to-end flows through a real running
backoffice are `feature-build`'s "smoke the real entry point" step, a different layer, not
this skill's job.

## The shape: Feature > Scenario > Specification

Unlike C#, JavaScript test frameworks have native nested blocks, so the mapping is direct:

```ts
import { fixture, html, expect } from "@open-wc/testing";
import "./feature-card.element.js";
import type { UmbFeatureCardElement } from "./feature-card.element.js";

// STORY-014 — Feature card shows the linked shipping profile
describe("Feature: feature card", () => {
  describe("Scenario: a valid shipping profile is linked", () => {
    let el: UmbFeatureCardElement;

    beforeEach(async () => {
      el = await fixture(html`<umb-feature-card .profileAlias=${"standard-post"}></umb-feature-card>`);
    });

    it("renders the profile's alias", () => {
      expect(el.shadowRoot!.textContent).to.include("standard-post");
    });

    it("dispatches a change event when the alias updates", async () => {
      const spy = /* set up a spy/listener on el */ null;
      // ... exactly one assertion on the dispatched event
    });
  });

  describe("Scenario: no shipping profile is linked", () => {
    let el: UmbFeatureCardElement;

    beforeEach(async () => {
      el = await fixture(html`<umb-feature-card></umb-feature-card>`);
    });

    it("renders an empty-state message", () => {
      expect(el.shadowRoot!.textContent).to.include("No shipping profile");
    });
  });
});
```

- **Feature** → the outermost `describe`, titled `Feature: …`, one per file.
- **Scenario** → a nested `describe`, titled `Scenario: …`. Arrange **all** of a scenario's
  required state in a `beforeEach` — render the component with `fixture()` there, not inside
  the `it` blocks.
- **Specification** → an `it`, exactly one assertion — a real DOM/shadow-DOM assertion or a
  dispatched-event assertion, not an internal-state check that bypasses what the component
  actually renders or emits.
- **Stub collaborators at the component's real boundary** — a context or repository the
  component consumes — rather than mocking network calls inside the component itself. If the
  component consumes an Umbraco state/context observable (see the official Backoffice Skills
  plugin's `umbraco-state-management` and this plugin's `umbraco-backoffice-conventions` for
  that pattern), provide a fake context exposing the same observable shape, not a real backend
  call. The fake has to be a real Umbraco context on an Umbraco host, not a plain object;
  `umbraco-test-setup`'s "Backoffice element tests" section shows how, and how to load the
  package's translations.
- **New specs pending by default** — `it.skip("pending implementation", () => { ... })` (Mocha
  BDD interface, which both Web Test Runner and Vitest support) until a `builder` task makes
  it pass.

**File / naming:** one spec file per Feature, kebab-case, matching the component it exercises
(e.g. `feature-card.test.ts`, the suffix the CMS backoffice's test runner looks for), never named for the story id. Put the story id in a single
comment at the top of the file — the only place it appears.
