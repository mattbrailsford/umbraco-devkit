#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# MyCompany.Newsletter

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
MD
mkdir -p docs/plans/topic-tier-badge src/MyCompany.Newsletter.Client/components src/MyCompany.Newsletter.Client/members
cat > docs/plans/topic-tier-badge/README.md <<'MD'
# Topic tier badge

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — show the same VIP tier pill on the Topics dashboard
2. [ ] [ARCHITECTURE.md](./ARCHITECTURE.md) — <pending>
3. [ ] [SPEC.md](./SPEC.md) — <pending>
4. [ ] [STORIES.md](./STORIES.md) — <pending>
5. [ ] [PLAN.md](./PLAN.md) — <pending>
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
MD
cat > docs/plans/topic-tier-badge/BRIEF.md <<'MD'
# Brief

## Problem

Top-tier subscribers already get a small "VIP" pill next to their name in the Members list,
so editors can spot them at a glance. Editors asked for the same tier indicator to show next
to a topic's top subscriber on the Topics dashboard, so it reads as the same recognised
programme members already see elsewhere, not a new badge.

## Who

Editors managing newsletter topics.

## Success

A topic's top subscriber on the Topics dashboard carries the same VIP treatment members
already see in the Members list.

## Out of scope

Changing who qualifies as VIP. Showing the badge anywhere else for now.
MD
cat > docs/plans/topic-tier-badge/DECISION-LOG.md <<'MD'
# Decision log
MD
cat > src/MyCompany.Newsletter.Client/components/tier-pill.element.ts <<'TS'
import { LitElement, html, css } from 'lit';
import { customElement } from 'lit/decorators.js';

/**
 * Small badge shown next to a subscriber's name when they're in the loyalty programme's top
 * tier. Used today in the Members list; reuse this look wherever a top-tier subscriber needs
 * the same treatment, rather than drawing a new badge.
 */
@customElement('mc-tier-pill')
export class McTierPillElement extends LitElement {
	static styles = css`
		:host {
			display: inline-flex;
			align-items: center;
			padding: 2px 10px;
			border-radius: 999px;
			background: #6a3fd1;
			color: #ffffff;
			font-size: 11px;
			font-weight: 700;
			text-transform: uppercase;
			letter-spacing: 0.03em;
		}
	`;

	render() {
		return html`<slot>VIP</slot>`;
	}
}

declare global {
	interface HTMLElementTagNameMap {
		'mc-tier-pill': McTierPillElement;
	}
}
TS
cat > src/MyCompany.Newsletter.Client/members/members-list.element.ts <<'TS'
import { LitElement, html } from 'lit';
import { customElement, property } from 'lit/decorators.js';
import '../components/tier-pill.element.js';

@customElement('mc-members-list')
export class McMembersListElement extends LitElement {
	@property({ type: Array })
	members: Array<{ name: string; email: string; isTopTier: boolean }> = [];

	render() {
		return html`
			<uui-table>
				${this.members.map(
					(m) => html`
						<uui-table-row>
							<uui-table-cell>${m.name} ${m.isTopTier ? html`<mc-tier-pill>VIP</mc-tier-pill>` : ''}</uui-table-cell>
							<uui-table-cell>${m.email}</uui-table-cell>
						</uui-table-row>
					`,
				)}
			</uui-table>
		`;
	}
}
TS
