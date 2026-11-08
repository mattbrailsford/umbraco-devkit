#!/usr/bin/env bash
set -euo pipefail
mkdir -p client/src/redirects
cat > client/package.json <<'JSON'
{
  "name": "redirects-client",
  "private": true,
  "type": "module",
  "devDependencies": { "@umbraco-cms/backoffice": "^17.0.0", "typescript": "^5.9.0", "vite": "^7.0.0" }
}
JSON
cat > client/src/redirects/redirects-dashboard.element.ts <<'TS'
import { css, customElement, html, repeat, state } from '@umbraco-cms/backoffice/external/lit';
import { UmbLitElement } from '@umbraco-cms/backoffice/lit-element';
import { umbOpenModal } from '@umbraco-cms/backoffice/modal';
import { RedirectsRepository, type RedirectRule } from './redirects.repository.js';
import { REDIRECT_RULE_MODAL } from './redirect-rule-modal.token.js';

@customElement('redirects-dashboard')
export class RedirectsDashboardElement extends UmbLitElement {
	#repository = new RedirectsRepository(this);
	@state() private _rules: RedirectRule[] = [];

	override connectedCallback() {
		super.connectedCallback();
		this.#load();
	}

	async #load() {
		const { data } = await this.#repository.requestAll();
		this._rules = data ?? [];
	}

	async #onAdd() {
		const value = await umbOpenModal(this, REDIRECT_RULE_MODAL, { data: { headline: 'Add redirect rule' } }).catch(
			() => undefined,
		);
		if (!value) return;
		await this.#repository.create(value.rule);
		this.#load();
	}

	override render() {
		return html`
			<uui-box headline="Redirect rules">
				<uui-button slot="header-actions" look="primary" label="Add rule" @click=${this.#onAdd}></uui-button>
				<uui-table>
					<uui-table-head>
						<uui-table-head-cell>From</uui-table-head-cell>
						<uui-table-head-cell>To</uui-table-head-cell>
						<uui-table-head-cell>Status</uui-table-head-cell>
					</uui-table-head>
					${repeat(
						this._rules,
						(rule) => rule.id,
						(rule) => html`
							<uui-table-row>
								<uui-table-cell>${rule.fromPath}</uui-table-cell>
								<uui-table-cell>${rule.toUrl}</uui-table-cell>
								<uui-table-cell>${rule.statusCode}</uui-table-cell>
							</uui-table-row>
						`,
					)}
				</uui-table>
			</uui-box>
		`;
	}

	static override styles = [
		css`
			:host {
				display: block;
				padding: var(--uui-size-layout-1);
			}
		`,
	];
}

export default RedirectsDashboardElement;

declare global {
	interface HTMLElementTagNameMap {
		'redirects-dashboard': RedirectsDashboardElement;
	}
}
TS
cat > client/src/redirects/redirects.repository.ts <<'TS'
import type { UmbControllerHost } from '@umbraco-cms/backoffice/controller-api';
import { UmbControllerBase } from '@umbraco-cms/backoffice/class-api';

export interface RedirectRule {
	id: string;
	fromPath: string;
	toUrl: string;
	statusCode: 301 | 302;
}

export class RedirectsRepository extends UmbControllerBase {
	constructor(host: UmbControllerHost) {
		super(host);
	}

	async requestAll(): Promise<{ data?: RedirectRule[]; error?: Error }> {
		return { data: [] };
	}

	async requestById(id: string): Promise<{ data?: RedirectRule; error?: Error }> {
		return { data: undefined };
	}

	async create(rule: Omit<RedirectRule, 'id'>): Promise<{ error?: Error }> {
		return {};
	}

	async update(rule: RedirectRule): Promise<{ error?: Error }> {
		return {};
	}
}
TS
cat > client/src/redirects/redirect-rule-modal.token.ts <<'TS'
import { UmbModalToken } from '@umbraco-cms/backoffice/modal';
import type { RedirectRule } from './redirects.repository.js';

export interface RedirectRuleModalData {
	headline: string;
	rule?: RedirectRule;
}

export interface RedirectRuleModalValue {
	rule: Omit<RedirectRule, 'id'>;
}

export const REDIRECT_RULE_MODAL = new UmbModalToken<RedirectRuleModalData, RedirectRuleModalValue>(
	'Redirects.Modal.Rule',
	{ modal: { type: 'sidebar', size: 'small' } },
);
TS
cat > client/src/redirects/redirect-rule-modal.element.ts <<'TS'
import { customElement, html, state } from '@umbraco-cms/backoffice/external/lit';
import { UmbModalBaseElement } from '@umbraco-cms/backoffice/modal';
import type { RedirectRuleModalData, RedirectRuleModalValue } from './redirect-rule-modal.token.js';

@customElement('redirect-rule-modal')
export class RedirectRuleModalElement extends UmbModalBaseElement<RedirectRuleModalData, RedirectRuleModalValue> {
	@state() private _fromPath = '';
	@state() private _toUrl = '';
	@state() private _statusCode: 301 | 302 = 301;

	#onSubmit() {
		this.value = { rule: { fromPath: this._fromPath, toUrl: this._toUrl, statusCode: this._statusCode } };
		this._submitModal();
	}

	override render() {
		return html`
			<umb-body-layout headline=${this.data?.headline ?? ''}>
				<uui-box>
					<umb-property-layout label="From path">
						<uui-input slot="editor" label="From path" .value=${this._fromPath}
							@input=${(e: InputEvent) => (this._fromPath = (e.target as HTMLInputElement).value)}></uui-input>
					</umb-property-layout>
					<umb-property-layout label="To URL">
						<uui-input slot="editor" label="To URL" .value=${this._toUrl}
							@input=${(e: InputEvent) => (this._toUrl = (e.target as HTMLInputElement).value)}></uui-input>
					</umb-property-layout>
					<umb-property-layout label="Status code">
						<uui-select slot="editor" label="Status code"
							.options=${[
								{ name: '301 Permanent', value: '301', selected: this._statusCode === 301 },
								{ name: '302 Temporary', value: '302', selected: this._statusCode === 302 },
							]}
							@change=${(e: Event) => (this._statusCode = Number((e.target as HTMLSelectElement).value) as 301 | 302)}></uui-select>
					</umb-property-layout>
				</uui-box>
				<uui-button slot="actions" label="Close" @click=${this._rejectModal}></uui-button>
				<uui-button slot="actions" look="primary" color="positive" label="Save" @click=${this.#onSubmit}></uui-button>
			</umb-body-layout>
		`;
	}
}

export default RedirectRuleModalElement;
TS
cat > client/src/redirects/manifests.ts <<'TS'
export const manifests: Array<UmbExtensionManifest> = [
	{
		type: 'dashboard',
		alias: 'Redirects.Dashboard',
		name: 'Redirects Dashboard',
		element: () => import('./redirects-dashboard.element.js'),
		meta: { label: 'Redirects', pathname: 'redirects' },
		conditions: [{ alias: 'Umb.Condition.SectionAlias', match: 'Umb.Section.Content' }],
	},
	{
		type: 'modal',
		alias: 'Redirects.Modal.Rule',
		name: 'Redirect Rule Modal',
		element: () => import('./redirect-rule-modal.element.js'),
	},
];
TS
