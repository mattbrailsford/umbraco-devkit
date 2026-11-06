#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# MyCompany.Assistant

An Umbraco 17 package (C# plus a Lit backoffice client) that adds an assistant chat panel,
docked on the right of the backoffice, available from every section. Most of the package's
features are built into that panel. Trunk branch: `main`.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`. Closed
plans move to `docs/archive/plans/<feature-slug>/`. Ideas live in `docs/ideas/`.
MD
mkdir -p src/MyCompany.Assistant/Client/src/chat docs/plans/pinned-messages/mockups
cat > src/MyCompany.Assistant/Client/src/chat/chat-panel.element.ts <<'TS'
import { css, customElement, html, repeat, state } from '@umbraco-cms/backoffice/external/lit';
import { UmbLitElement } from '@umbraco-cms/backoffice/lit-element';
import type { ChatMessage } from './types.js';

@customElement('assistant-chat-panel')
export class AssistantChatPanelElement extends UmbLitElement {
	@state() private _messages: Array<ChatMessage> = [];

	override render() {
		return html`
			<div id="header">
				<umb-icon name="icon-chat"></umb-icon>
				<span id="title">Assistant</span>
				<uui-button compact label="Close"><uui-icon name="icon-wrong"></uui-icon></uui-button>
			</div>
			<div id="thread">
				${repeat(this._messages, (m) => m.id, (m) => html`<div class="message ${m.role}">${m.text}</div>`)}
			</div>
			<div id="composer">
				<uui-textarea label="Message" placeholder="Ask the assistant"></uui-textarea>
				<uui-button look="primary" label="Send"></uui-button>
			</div>
		`;
	}

	static override styles = css`
		:host {
			position: fixed;
			top: 60px;
			right: 0;
			bottom: 0;
			width: 400px;
			display: flex;
			flex-direction: column;
			background: var(--uui-color-surface);
			border-left: 1px solid var(--uui-color-border);
			box-shadow: var(--uui-shadow-depth-3);
		}
		#header {
			display: flex;
			align-items: center;
			gap: var(--uui-size-space-3);
			height: 50px;
			padding: 0 var(--uui-size-space-4);
			border-bottom: 1px solid var(--uui-color-border);
		}
		#title {
			flex: 1;
			font-weight: 700;
		}
		#thread {
			flex: 1;
			overflow: auto;
			display: flex;
			flex-direction: column;
			gap: var(--uui-size-space-3);
			padding: var(--uui-size-space-4);
		}
		.message {
			max-width: 85%;
			padding: var(--uui-size-space-3) var(--uui-size-space-4);
			border-radius: var(--uui-border-radius);
			line-height: 1.5;
		}
		.message.user {
			align-self: flex-end;
			background: var(--uui-color-selected);
			color: var(--uui-color-selected-contrast);
		}
		.message.assistant {
			align-self: flex-start;
			background: var(--uui-color-surface-alt);
		}
		#composer {
			display: flex;
			gap: var(--uui-size-space-3);
			padding: var(--uui-size-space-4);
			border-top: 1px solid var(--uui-color-border);
		}
		#composer uui-textarea {
			flex: 1;
		}
	`;
}
TS
cat > docs/plans/pinned-messages/README.md <<'MD'
# Pinned messages

Read these in order:

1. [x] [BRIEF.md](./BRIEF.md) — let editors pin assistant answers they keep coming back to
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — a pin action on messages and a pinned list, both in the chat panel
3. [x] [SPEC.md](./SPEC.md) — two panel states; their mockups still pending
4. [ ] [STORIES.md](./STORIES.md) — <pending>
5. [ ] [PLAN.md](./PLAN.md) — <pending>
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>

See [DECISION-LOG.md](./DECISION-LOG.md) for why things changed along the way.
MD
cat > docs/plans/pinned-messages/BRIEF.md <<'MD'
# Brief

## Problem

Editors ask the assistant the same questions again because a useful answer scrolls away in
the thread. They want to keep the answers they rely on within reach.

## Who

Editors who use the assistant panel daily.

## Success

An editor pins an answer in one click and finds it again in under five seconds, from any
section.

## Out of scope

Sharing pins with other users. Pinning the editor's own messages.
MD
cat > docs/plans/pinned-messages/ARCHITECTURE.md <<'MD'
# Architecture

## Extension points

All inside the existing assistant chat panel (`assistant-chat-panel`): a pin action on each
assistant message, and a "Pinned" view in the same panel. No new section or screen.

## Key decisions

- **In the panel, not a dashboard.** Pins are needed while working in any section, which is
  where the panel already is.
MD
cat > docs/plans/pinned-messages/SPEC.md <<'MD'
# Spec

## Frontend components

### Thread with a pinned answer

<!-- Mockup still pending (`mockups/thread-pinned.html`). -->

The chat panel over the Content section. A thread of four messages; one assistant answer is
pinned and shows it. Every assistant answer has a pin action.

### Pinned list

<!-- Mockup still pending (`mockups/pinned-list.html`). -->

The same panel switched to its "Pinned" view: three pinned answers, newest first, each with
the question it answered, when it was pinned, and an unpin action. A way back to the thread.
MD
cat > docs/plans/pinned-messages/DECISION-LOG.md <<'MD'
# Decision log

- 03-11-2026 — In the panel, not a dashboard (see ARCHITECTURE.md).
MD
