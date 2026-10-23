# Diagram conventions for a PR description

## Contents

- Pseudocode — a changed algorithm or business rule
- Call chain — changed control flow
- Shallow file tree — changed responsibilities
- EF Core / SQL — a table or migration change
- Lit component tree — changed backoffice UI
- Manifest / composer registration — a changed extension point
- Backoffice registrations — what was added to the backoffice
- Settings — new or changed configuration
- Management API endpoints — new or changed routes
- Data structure / contract — a new or changed type
- Picture diagrams — from the plan folder's `diagrams/`
- Rule of thumb

When the plan folder has `diagrams/`, its pictures come first (see "Picture diagrams" below);
these text views add the detail a picture can't carry, such as exact JSON, columns or
signatures.

Pick the smallest view that makes the key point clear. Skip any view that doesn't apply — a
one-file bug fix might use none of these and just need "Why" and "Special things to note."

Use a `diff` block when the point is what changed and the surrounding shape already exists.
Show the whole block, undiffed, when most of it is new, or when trimming context would hide
who owns what or in what order things happen.

## Pseudocode — a changed algorithm or business rule

```diff
 on(PublishContent)
-  save content
+  save content
+  if content has scheduled unpublish date
+    queue unpublish job
```

## Call chain — changed control flow

```diff
 ContentController.PublishContent
   ContentService.Save
+    ScheduledPublishService.QueueUnpublish
   ContentService.Publish
```

## Shallow file tree — changed responsibilities

```diff
 src/
 ├── Services/
+│   └── ScheduledPublishService.cs   # queues/cancels scheduled unpublish jobs
 ├── Notifications/
-└── ContentPublishedHandler.cs
+└── ContentPublishedHandler.cs        # now also cancels a pending unpublish
```

## EF Core / SQL — a table or migration change

```diff
 CREATE TABLE ScheduledUnpublish (
   Id INT PRIMARY KEY,
   ContentKey UNIQUEIDENTIFIER NOT NULL,
+  UnpublishDate DATETIME2 NOT NULL,
+  CONSTRAINT FK_ScheduledUnpublish_Content FOREIGN KEY (ContentKey)
+    REFERENCES umbracoNode(uniqueID)
 )
```

Show the whole `CREATE TABLE`/entity when the table is new; diff it when adding or changing a
column on an existing one.

## Lit component tree — changed backoffice UI

```diff
 <my-package-workspace-view> (client/src/workspace)
   @state() private _content
+  @state() private _scheduledUnpublishDate
   <uui-box>
+    <uui-input type="datetime-local">
```

Note properties/state and package boundaries that matter to the change, not every attribute.

## Manifest / composer registration — a changed extension point

Umbraco-specific: most backoffice extensions and server-side pipeline hooks register through a
manifest entry or a `Composer`/`IComposer`, not through code a reviewer will stumble onto by
reading top to bottom. Show the registration diff explicitly — it's easy to miss in a large
diff otherwise.

```diff
 {
   "type": "workspaceView",
   "alias": "MyPackage.WorkspaceView.ScheduledUnpublish",
+  "name": "Scheduled Unpublish Workspace View",
+  "js": "/App_Plugins/MyPackage/workspace-view.js",
+  "conditions": [
+    { "alias": "Umb.Condition.WorkspaceAlias", "match": "Umb.Workspace.Document" }
+  ]
 }
```

## Backoffice registrations — what was added to the backoffice

The manifest diff above shows the exact JSON; this table is the readable summary of it. One
row per extension the PR adds or changes, so a reviewer can see the whole footprint at once.

| Type | Name | Where it appears |
|---|---|---|
| Workspace view | Deliveries | Webhook editor, as a tab after Details |
| Entity action | Resend delivery | "..." menu on a webhook in the tree |
| Dashboard | Usage | AI section, second dashboard tab |

Use the editor-facing name and place, not the alias. Leave out extensions with no visible
footprint (a condition, a repository) unless they're the point of the PR.

## Settings — new or changed configuration

Show any new `appsettings.json` options as they'd appear in a site's config, with their
default values and a short comment on each. Site owners copy this straight into their own
config, so it must be valid JSON once the comments are removed.

```jsonc
{
  "Umbraco": {
    "MyPackage": {
      "Deliveries": {
        "RetryCount": 3,          // attempts before a delivery is marked failed
        "RetentionDays": 30       // how long delivery history is kept
      }
    }
  }
}
```

## Management API endpoints — new or changed routes

One row per endpoint. "Who can call it" is the authorization policy in plain words.

| Method | Route | Who can call it | What it does |
|---|---|---|---|
| `GET` | `/umbraco/management/api/v1/my-package/deliveries` | Users with access to the Settings section | Lists deliveries, newest first |
| `POST` | `/umbraco/management/api/v1/my-package/deliveries/{id}/resend` | Same | Queues a delivery to send again |

Diff the table when changing an existing set of routes.

## Data structure / contract — a new or changed type

Show the complete shape when it's new or central to the change; diff it when adding to an
existing one.

```csharp
public record ScheduledUnpublishRequest(Guid ContentKey, DateTime UnpublishDate);
```

## Picture diagrams — from the plan folder's `diagrams/`

`feature-design` draws SVG diagrams of the flow, call order, statuses, data model or layers.
Show each one that matches what the PR built, under a one-line caption, linked by full URL
pinned to the pushed commit:

```md
How a delivery moves from publish to delivered or dead-lettered.

![Delivery flow](https://github.com/<owner>/<repo>/blob/<sha>/docs/plans/<feature-slug>/diagrams/delivery-flow.svg?raw=true)
```

Don't redraw them here. A picture replaces the text view that tells the same story:

- a flow or sequence picture replaces the call chain and the pseudocode
- a component-tree picture replaces the Lit component tree
- a data-model picture replaces the table block, unless a column's exact type or constraint
  is the point

Text views that hold exact values stay, picture or not: the manifest or composer diff, the
backoffice registrations table, settings, API endpoints, a data contract, and a file tree.

## Rule of thumb

Tell the story in the order a reader needs it — a data structure or contract usually comes
before the code that consumes it, a table before the query that reads it. All views are
optional; use only the ones that carry weight for this specific PR.
