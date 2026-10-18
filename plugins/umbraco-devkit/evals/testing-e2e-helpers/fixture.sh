#!/usr/bin/env bash
set -euo pipefail
c=Client
mkdir -p $c/src/reading-time $c/src/lang demo/ReadingTime.Demo/Properties

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

cat > $c/package.json <<'EOF'
{
  "name": "umbraco-community-reading-time",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "vite build"
  },
  "devDependencies": {
    "@umbraco-cms/backoffice": "^17.0.0",
    "typescript": "^5.9.0",
    "vite": "^7.1.0"
  }
}
EOF

cat > demo/ReadingTime.Demo/ReadingTime.Demo.csproj <<'EOF'
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms" Version="17.7.1" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\Umbraco.Community.ReadingTime\Umbraco.Community.ReadingTime.csproj" />
  </ItemGroup>
</Project>
EOF

cat > demo/ReadingTime.Demo/appsettings.Development.json <<'EOF'
{
  "ConnectionStrings": {
    "umbracoDbDSN": "Data Source=|DataDirectory|/Umbraco.sqlite.db;Cache=Shared;Foreign Keys=True;Pooling=True",
    "umbracoDbDSN_ProviderName": "Microsoft.Data.Sqlite"
  },
  "Umbraco": {
    "CMS": {
      "Unattended": {
        "InstallUnattended": true,
        "UnattendedUserName": "Demo Admin",
        "UnattendedUserEmail": "admin@example.com",
        "UnattendedUserPassword": "change-me-locally"
      }
    }
  }
}
EOF

cat > demo/ReadingTime.Demo/Properties/launchSettings.json <<'EOF'
{
  "profiles": {
    "ReadingTime.Demo": {
      "commandName": "Project",
      "launchBrowser": true,
      "applicationUrl": "https://localhost:44355",
      "environmentVariables": { "ASPNETCORE_ENVIRONMENT": "Development" }
    }
  }
}
EOF

mkdir -p src/Umbraco.Community.ReadingTime
cat > src/Umbraco.Community.ReadingTime/Umbraco.Community.ReadingTime.csproj <<'EOF'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <StaticWebAssetBasePath>App_Plugins/ReadingTime</StaticWebAssetBasePath>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Api.Management" Version="[17.0.0, 18)" />
  </ItemGroup>
</Project>
EOF
