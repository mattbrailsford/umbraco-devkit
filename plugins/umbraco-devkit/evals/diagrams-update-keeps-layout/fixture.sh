#!/usr/bin/env bash
set -euo pipefail
cat > CLAUDE.md <<'MD'
# Umbraco.Community.Webhooks

An Umbraco 17 package (C# plus a Lit backoffice client) that sends webhooks when content is
published.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`.
MD
mkdir -p docs/plans/signed-resend/diagrams
cat > docs/plans/signed-resend/ARCHITECTURE.md <<'MD'
# Signed payloads and resend: architecture

## Delivery flow

![Delivery flow](./diagrams/delivery-flow.svg)

The diagram shows delivery as it works today, before this feature.

## Signing

`PayloadSigner` signs each payload with HMAC-SHA256 using the endpoint's `Secret` and adds an
`X-Signature` header. `WebhookDeliveryJob` calls it after picking a row and before the POST.

## Resend

The "Webhook deliveries" dashboard gets a Resend action on DeadLettered rows. It calls
`POST /umbraco/management/api/v1/webhook-deliveries/{id}/resend`, which sets the row back to
Pending with attempts = 0, so the job picks it up on its next run.
MD
cat > docs/plans/signed-resend/diagrams/delivery-flow.svg <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="960" height="820" viewBox="0 0 960 820">
  <style id="theme"><![CDATA[
/* Diagram styles: the neutral theme (colour variables, light and dark), then the shapes that use them. */
svg {
  --font: system-ui, -apple-system, "Segoe UI", sans-serif;
  --stroke-width: 1px;
  --bg: #ffffff; --text: #0f172a; --muted: #475569; --edge: #334155;
  --zone-fill: none; --zone-stroke: #94a3b8;
  --node-fill: #f8fafc; --node-stroke: #475569; --decision-fill: #f8fafc;
  --store-fill: #eef2ff; --store-lid: #e0e7ff; --store-stroke: #4f46e5;
  --ok-fill: #f0fdf4; --ok-stroke: #16a34a; --ok-text: #14532d;
  --fail-fill: #fef2f2; --fail-stroke: #dc2626; --fail-text: #7f1d1d;
  --new-fill: #fff7ed; --new-stroke: #ea580c; --new-text: #c2410c;
  --table-head: #eef2ff; --table-head-text: #1e1b4b; --table-row-alt: #f8fafc;
  --pk: #c2410c; --fk: #4f46e5;
}
@media (prefers-color-scheme: dark) {
  svg {
    /* plain greys, close to VS Code's Dark Modern theme */
    --bg: #1f1f1f; --text: #e0e0e0; --muted: #a0a0a0; --edge: #a0a0a0;
    --zone-stroke: #4a4a4a;
    --node-fill: #2b2b2b; --node-stroke: #6b6b6b; --decision-fill: #2b2b2b;
    --store-fill: #2a2d36; --store-lid: #343844; --store-stroke: #8c95c9;
    --ok-fill: #1f2d24; --ok-stroke: #4fb36b; --ok-text: #8fd9a5;
    --fail-fill: #332223; --fail-stroke: #e05d5d; --fail-text: #f0a0a0;
    --new-fill: #35281c; --new-stroke: #f0883e; --new-text: #ffb77c;
    --table-head: #333333; --table-head-text: #e0e0e0; --table-row-alt: #252525;
    --pk: #ffb77c; --fk: #9fa8da;
  }
}

svg { font-family: var(--font); font-size: 13px; }
.bg { fill: var(--bg); }

/* Regions: a dashed box grouping nodes by where they run */
.zone { fill: var(--zone-fill); stroke: var(--zone-stroke); stroke-dasharray: 6 4; }
.zone-title { fill: var(--muted); font-size: 12px; font-weight: 600; }
.zone-note { fill: var(--muted); font-size: 11px; }

/* Nodes: a g.node (plus .store, .decision, .ok, .fail or .new) holding a .shape and its texts */
.node .shape { fill: var(--node-fill); stroke: var(--node-stroke); stroke-width: var(--stroke-width); }
.node .title { fill: var(--text); font-weight: 600; text-anchor: middle; }
.node .sub { fill: var(--muted); font-size: 12px; text-anchor: middle; }
.node.store .shape { fill: var(--store-fill); stroke: var(--store-stroke); }
.node.store .lid { fill: var(--store-lid); stroke: var(--store-stroke); stroke-width: var(--stroke-width); }
.node.decision .shape { fill: var(--decision-fill); }
.node.ok .shape { fill: var(--ok-fill); stroke: var(--ok-stroke); }
.node.ok .title, .node.ok .sub { fill: var(--ok-text); }
.node.fail .shape { fill: var(--fail-fill); stroke: var(--fail-stroke); }
.node.fail .title, .node.fail .sub { fill: var(--fail-text); }
.node.new .shape { fill: var(--new-fill); stroke: var(--new-stroke); stroke-width: calc(var(--stroke-width) + 1px); }
.node.new .title, .node.new .sub, .node .new-text { fill: var(--new-text); }

/* Tables (data models): a g.table holding .shape, .head, .row-alt, and .col/.type/.pk/.fk texts */
.table .shape { fill: var(--node-fill); stroke: var(--node-stroke); stroke-width: var(--stroke-width); }
.table .head { fill: var(--table-head); stroke: var(--node-stroke); stroke-width: var(--stroke-width); }
.table .head-text { fill: var(--table-head-text); font-weight: 600; font-size: 14px; }
.table .row-alt { fill: var(--table-row-alt); }
.table .col { fill: var(--text); }
.table .col.keycol { font-weight: 600; }
.table .type { fill: var(--muted); font-size: 12px; text-anchor: end; }
.table .pk { fill: var(--pk); font-size: 11px; font-weight: 700; }
.table .fk { fill: var(--fk); font-size: 11px; font-weight: 700; }

/* Connectors */
.edge { fill: none; stroke: var(--edge); stroke-width: 1.5px; }
.edge.new { stroke: var(--new-stroke); stroke-width: 2px; }
.edge-label { fill: var(--muted); font-size: 11px; }
.edge-label.new { fill: var(--new-text); font-weight: 600; }
.arrowhead { fill: var(--edge); }
.arrowhead.new { fill: var(--new-stroke); }

/* Legend chip */
.legend .shape { fill: var(--new-fill); stroke: var(--new-stroke); }
.legend text { fill: var(--new-text); font-size: 11px; font-weight: 600; text-anchor: middle; }
.footnote { fill: var(--muted); font-size: 11px; }


/* Sequence diagrams: .actor boxes on top (use .node), .lifeline down from each, .activation bars */
.lifeline { stroke: var(--zone-stroke); stroke-width: 1px; stroke-dasharray: 4 4; fill: none; }
.activation { fill: var(--node-fill); stroke: var(--node-stroke); stroke-width: var(--stroke-width); }
.edge.return, .edge.dashed { stroke-dasharray: 5 4; }

/* State diagrams: states are .node with a large rx; .start is a filled dot, .end a ringed dot */
.start { fill: var(--text); }
.end { fill: var(--bg); stroke: var(--text); stroke-width: 1.5px; }
.end-dot { fill: var(--text); }

/* Layered architecture: .band is a solid row behind a layer's nodes, .band-title names it */
.band { fill: var(--table-row-alt); stroke: var(--zone-stroke); stroke-width: 1px; }
.band-title { fill: var(--muted); font-size: 12px; font-weight: 600; }

/* Notes and section headings */
.note .shape { fill: var(--table-row-alt); stroke: var(--zone-stroke); stroke-dasharray: 3 3; }
.note text { fill: var(--muted); font-size: 11px; }
.heading { fill: var(--text); font-size: 15px; font-weight: 700; }
.mono { font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace; font-size: 12px; }
.edge-label.center { text-anchor: middle; }
.edge-label.end { text-anchor: end; }

/* Charts: axes, gridlines, bars (.before/.after or plain), line series and their points */
.axis { stroke: var(--muted); stroke-width: 1px; fill: none; }
.gridline { stroke: var(--zone-stroke); stroke-width: 1px; stroke-dasharray: 2 3; fill: none; }
.axis-label { fill: var(--muted); font-size: 11px; }
.axis-title { fill: var(--muted); font-size: 12px; font-weight: 600; }
.value-label { fill: var(--text); font-size: 11px; font-weight: 600; }
.bar { fill: var(--store-lid); stroke: var(--store-stroke); stroke-width: 1px; }
.bar.before { fill: var(--zone-stroke); stroke: var(--node-stroke); }
.bar.after { fill: var(--store-lid); stroke: var(--store-stroke); }
.bar.new { fill: var(--new-fill); stroke: var(--new-stroke); }
.series { fill: none; stroke: var(--store-stroke); stroke-width: 2px; }
.series.alt { stroke: var(--new-stroke); }
.series.muted { stroke: var(--node-stroke); stroke-dasharray: 5 4; }
.point { fill: var(--bg); stroke: var(--store-stroke); stroke-width: 2px; }
.point.alt { stroke: var(--new-stroke); }
.threshold { stroke: var(--fail-stroke); stroke-width: 1.5px; stroke-dasharray: 6 4; fill: none; }
.threshold-label { fill: var(--fail-text); font-size: 11px; font-weight: 600; }
.swatch { stroke-width: 1px; }
.point.muted { stroke: var(--node-stroke); }

/* Highlight one path through the diagram. Not the same as .new, which means "new in this change". */
.node.focus .shape { stroke: var(--store-stroke); stroke-width: calc(var(--stroke-width) + 1px); }
.edge.focus { stroke: var(--store-stroke); stroke-width: 2.5px; }
.edge-label.focus { fill: var(--store-stroke); font-weight: 600; }

/* A part that exists but does nothing here: skipped on this server, unused by this screen */
.node.inactive .shape { fill: none; stroke-dasharray: 4 3; }
.node.inactive .title, .node.inactive .sub { fill: var(--muted); font-weight: 400; }

/* Left-aligned text inside a node or note, for lists and trees */
.node .left, .note .left { text-anchor: start; }

/* Numbered badges that tie matching parts together (before/after, steps) */
.badge { fill: var(--text); }
.badge-text { fill: var(--bg); font-size: 10px; font-weight: 700; text-anchor: middle; }

/* Divider between columns, legend labels, and sequence-diagram alt/opt frames */
.divider { fill: none; stroke: var(--zone-stroke); stroke-width: 1px; stroke-dasharray: 4 4; }
.legend-label { fill: var(--muted); font-size: 11px; }
.frame { fill: none; stroke: var(--node-stroke); stroke-width: 1px; }
.frame-tag { fill: var(--node-fill); stroke: var(--node-stroke); stroke-width: 1px; }
.frame-tag-text { fill: var(--text); font-size: 11px; font-weight: 700; }
.guard { fill: var(--muted); font-size: 11px; font-style: italic; }

]]></style>
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse">
      <path class="arrowhead" d="M0,0 L10,5 L0,10 z"/>
    </marker>
    <marker id="arrow-new" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse">
      <path class="arrowhead new" d="M0,0 L10,5 L0,10 z"/>
    </marker>
  </defs>
  <rect class="bg" width="960" height="820"/>

  <rect class="zone" x="20" y="20" width="260" height="196" rx="10"/>
  <text class="zone-title" x="32" y="40">Any server (load balanced)</text>

  <rect class="zone" x="300" y="20" width="640" height="680" rx="10"/>
  <text class="zone-title" x="316" y="42">SchedulingPublisher server only</text>
  <text class="zone-note" x="316" y="58">Subscriber servers skip the job</text>

  <g class="node">
    <rect class="shape" x="40" y="54" width="220" height="48" rx="6"/>
    <text class="title" x="150" y="74">Editor publishes content</text>
    <text class="sub" x="150" y="92">backoffice</text>
  </g>

  <g class="node">
    <rect class="shape" x="40" y="132" width="220" height="68" rx="6"/>
    <text class="title" x="150" y="152" font-size="12">ContentPublishedNotification</text>
    <text class="title" x="150" y="170" font-size="12">handler</text>
    <text class="sub" x="150" y="188">sends nothing</text>
  </g>

  <g class="node store">
    <path class="shape" d="M40,266 v48 a110,8 0 0 0 220,0 v-48"/>
    <ellipse class="lid" cx="150" cy="266" rx="110" ry="8"/>
    <text class="title" x="150" y="294">WebhookOutbox</text>
    <text class="sub" x="150" y="311">EF Core table</text>
  </g>

  <g class="node">
    <rect class="shape" x="430" y="72" width="260" height="52" rx="6"/>
    <text class="title" x="560" y="94">IRecurringBackgroundJob</text>
    <text class="sub" x="560" y="112">runs every 10 s</text>
  </g>

  <g class="node">
    <rect class="shape" x="430" y="156" width="260" height="52" rx="6"/>
    <text class="title" x="560" y="178">Pick due outbox rows</text>
    <text class="sub" x="560" y="196">Pending, NextAttemptAt &lt;= now</text>
  </g>

  <g class="node">
    <rect class="shape" x="430" y="316" width="260" height="52" rx="6"/>
    <text class="title" x="560" y="338">POST payload to endpoint URL</text>
    <text class="sub" x="560" y="356">HttpClient</text>
  </g>

  <g class="node decision">
    <path class="shape" d="M560,398 L630,430 L560,462 L490,430 z"/>
    <text class="title" x="560" y="435">2xx?</text>
  </g>

  <g class="node decision">
    <path class="shape" d="M560,506 L645,540 L560,574 L475,540 z"/>
    <text class="title" x="560" y="545" font-size="12">attempts &lt; 5?</text>
  </g>

  <g class="node ok">
    <rect class="shape" x="720" y="406" width="170" height="48" rx="6"/>
    <text class="title" x="805" y="426">Mark Delivered</text>
    <text class="sub" x="805" y="444">+ WebhookLog entry</text>
  </g>

  <g class="node fail">
    <rect class="shape" x="720" y="516" width="170" height="48" rx="6"/>
    <text class="title" x="805" y="536">Mark DeadLettered</text>
    <text class="sub" x="805" y="554">+ WebhookLog entry</text>
  </g>

  <g class="node">
    <rect class="shape" x="430" y="610" width="260" height="64" rx="6"/>
    <text class="title" x="560" y="630">attempts + 1</text>
    <text class="sub" x="560" y="647">NextAttemptAt = exponential backoff</text>
    <text class="sub" x="560" y="663">stays Pending</text>
  </g>

  <g class="node store">
    <path class="shape" d="M720,738 v48 a85,8 0 0 0 170,0 v-48"/>
    <ellipse class="lid" cx="805" cy="738" rx="85" ry="8"/>
    <text class="title" x="805" y="770">WebhookLog</text>
  </g>

  <g class="node">
    <rect class="shape" x="430" y="730" width="260" height="64" rx="6"/>
    <text class="title" x="560" y="752">Dashboard: Webhook deliveries</text>
    <text class="sub" x="560" y="770">backoffice, shows each attempt</text>
  </g>

  <g marker-end="url(#arrow)">
    <path class="edge" d="M150,102 V132"/>
    <path class="edge" d="M150,200 V256"/>
    <path class="edge" d="M260,290 H380 V182 H430"/>
    <path class="edge" d="M560,124 V156"/>
    <path class="edge" d="M560,208 V316"/>
    <path class="edge" d="M560,368 V398"/>
    <path class="edge" d="M630,430 H720"/>
    <path class="edge" d="M560,462 V506"/>
    <path class="edge" d="M645,540 H720"/>
    <path class="edge" d="M560,574 V610"/>
    <path class="edge" d="M430,642 H150 V324"/>
    <path class="edge" d="M890,430 H915 V762 H890"/>
    <path class="edge" d="M805,564 V728"/>
    <path class="edge" d="M720,762 H690"/>
  </g>

  <text class="edge-label" x="158" y="234">insert 1 row per endpoint,</text>
  <text class="edge-label" x="158" y="248">same scope as publish</text>
  <text class="edge-label" x="386" y="250">read</text>
  <text class="edge-label" x="662" y="423">yes</text>
  <text class="edge-label" x="568" y="489">no / timeout</text>
  <text class="edge-label" x="672" y="533">no</text>
  <text class="edge-label" x="568" y="596">yes</text>
  <text class="edge-label" x="160" y="636">picked up again next run</text>
  <text class="edge-label" x="692" y="752">reads</text>
</svg>
SVG
