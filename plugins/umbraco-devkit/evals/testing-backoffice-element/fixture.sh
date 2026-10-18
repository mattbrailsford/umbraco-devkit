#!/usr/bin/env bash
set -euo pipefail
c=Client
mkdir -p $c/src/reading-time $c/src/lang

cat > $c/package.json <<'EOF'
{
  "name": "umbraco-community-reading-time",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "vite build",
    "test": "web-test-runner"
  },
  "devDependencies": {
    "@open-wc/testing": "^4.0.0",
    "@umbraco-cms/backoffice": "^17.0.0",
    "@web/dev-server-esbuild": "^1.0.4",
    "@web/test-runner": "^0.20.2",
    "@web/test-runner-playwright": "^0.11.1",
    "typescript": "^5.9.0",
    "vite": "^7.1.0"
  }
}
EOF

cat > $c/web-test-runner.config.mjs <<'EOF'
import { esbuildPlugin } from '@web/dev-server-esbuild';
import { playwrightLauncher } from '@web/test-runner-playwright';

export default {
	files: ['./src/**/*.test.ts'],
	nodeResolve: true,
	browsers: [playwrightLauncher({ product: 'chromium' })],
	plugins: [esbuildPlugin({ ts: true, tsconfig: './tsconfig.json', target: 'auto' })],
};
EOF

cat > $c/tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "experimentalDecorators": true,
    "useDefineForClassFields": false,
    "strict": true,
    "skipLibCheck": true,
    "types": ["@umbraco-cms/backoffice/extension-types"]
  },
  "include": ["src"]
}
EOF

cat > $c/src/lang/en.ts <<'EOF'
export default {
	readingTime: {
		minutes: '%0% min read',
	},
};
EOF

cat > $c/src/manifests.ts <<'EOF'
export const manifests: Array<UmbExtensionManifest> = [
	{
		type: 'localization',
		alias: 'ReadingTime.Localization.En',
		name: 'Reading time English',
		meta: { culture: 'en' },
		js: () => import('./lang/en.js'),
	},
	{
		type: 'workspaceView',
		alias: 'ReadingTime.WorkspaceView',
		name: 'Reading time',
		element: () => import('./reading-time/reading-time-badge.element.js'),
		meta: { label: '#readingTime_minutes', pathname: 'reading-time', icon: 'icon-time' },
		conditions: [{ alias: 'Umb.Condition.WorkspaceAlias', match: 'Umb.Workspace.Document' }],
	},
];
EOF

cat > $c/src/reading-time/reading-time.context.ts <<'EOF'
import { UmbContextBase } from '@umbraco-cms/backoffice/class-api';
import { UmbContextToken } from '@umbraco-cms/backoffice/context-api';
import { UmbNumberState } from '@umbraco-cms/backoffice/observable-api';
import type { UmbControllerHost } from '@umbraco-cms/backoffice/controller-api';

export class ReadingTimeContext extends UmbContextBase {
	#minutes = new UmbNumberState(0);
	readonly minutes = this.#minutes.asObservable();

	constructor(host: UmbControllerHost) {
		super(host, READING_TIME_CONTEXT);
	}

	setMinutes(value: number) {
		this.#minutes.setValue(value);
	}
}

export const READING_TIME_CONTEXT = new UmbContextToken<ReadingTimeContext>('ReadingTimeContext');
EOF

cat > $c/src/reading-time/reading-time-badge.element.ts <<'EOF'
import { customElement, html, state } from '@umbraco-cms/backoffice/external/lit';
import { UmbLitElement } from '@umbraco-cms/backoffice/lit-element';
import { READING_TIME_CONTEXT } from './reading-time.context.js';

@customElement('reading-time-badge')
export class ReadingTimeBadgeElement extends UmbLitElement {
	@state() private _minutes = 0;

	constructor() {
		super();
		this.consumeContext(READING_TIME_CONTEXT, (context) => {
			this.observe(context?.minutes, (minutes) => (this._minutes = minutes ?? 0));
		});
	}

	override render() {
		return html`<uui-tag>${this.localize.term('readingTime_minutes', this._minutes)}</uui-tag>`;
	}
}

export default ReadingTimeBadgeElement;

declare global {
	interface HTMLElementTagNameMap {
		'reading-time-badge': ReadingTimeBadgeElement;
	}
}
EOF
