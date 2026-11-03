#!/usr/bin/env bash
set -euo pipefail
mkdir -p client/src
cat > CLAUDE.md <<'MD'
# Umbraco.Community.Redirects

An Umbraco package with a backoffice dashboard for managing redirects. The client in
`client/` is built with Vite and generates its API client with `@hey-api/openapi-ts`.
Branch per CMS major; this is the new `v19/dev` line.
MD
cat > client/package.json <<'JSON'
{
  "name": "umbraco-community-redirects-client",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "tsc && vite build",
    "generate-client": "openapi-ts"
  },
  "devDependencies": {
    "@hey-api/openapi-ts": "0.97.2",
    "@umbraco-cms/backoffice": "18.0.0",
    "typescript": "5.9.3",
    "vite": "7.1.12"
  }
}
JSON
cat > client/package-lock.json <<'JSON'
{
  "name": "umbraco-community-redirects-client",
  "lockfileVersion": 3,
  "requires": true,
  "packages": {
    "": {
      "name": "umbraco-community-redirects-client",
      "devDependencies": {
        "@hey-api/openapi-ts": "0.97.2",
        "@umbraco-cms/backoffice": "18.0.0",
        "typescript": "5.9.3",
        "vite": "7.1.12"
      }
    },
    "node_modules/@hey-api/openapi-ts": { "version": "0.97.2", "dev": true },
    "node_modules/@umbraco-cms/backoffice": {
      "version": "18.0.0",
      "dev": true,
      "peerDependencies": {
        "@hey-api/openapi-ts": ">=0.97.0 <1.0.0",
        "@umbraco-ui/uui": "^2.0.0",
        "lit": "^3.3.1",
        "rxjs": "^7.8.2"
      }
    }
  }
}
JSON
cat > client/src/index.ts <<'TS'
import { UmbLitElement } from "@umbraco-cms/backoffice/lit-element";
import { html, customElement } from "@umbraco-cms/backoffice/external/lit";

@customElement("redirects-dashboard")
export class RedirectsDashboard extends UmbLitElement {
  render() {
    return html`<uui-box headline="Redirects"></uui-box>`;
  }
}
TS
