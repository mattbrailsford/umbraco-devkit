# Diagram conventions for a PR description

## Contents

- Reading rules for every view
- Pseudocode — a changed algorithm or business rule
- Call chain — changed control flow
- Shallow file tree — changed responsibilities
- Database table — a table or migration change
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
one-file bug fix might use none of these and just need "Why" and "How to verify."

Use a `diff` block when the point is what changed and the surrounding shape already exists.
Show the whole block, undiffed, in its own language, when most of it is new, or when trimming
context would hide who owns what or in what order things happen.

## Reading rules for every view

- Red means removed. Never remove a line and add it back just to annotate it: a reader sees
  red and thinks it's gone. Leave a changed line as context and say what changed in a trailing
  comment (`# changed: ...`).
- Put one item per line (a parameter, a property, a child), so a diff marks only what was
  added instead of turning a whole rewritten line red and green.
- A table inside a `diff` block renders as raw pipes. Show a changed set of rows with a
  `Change` column (**New**, **Changed**, **Removed**) instead.
- Keep lines under about 90 characters; wider ones scroll sideways on GitHub.

## Pseudocode — a changed algorithm or business rule

Write the steps in plain words, not code.

```diff
 when content is published
   save content
+  if content has a scheduled unpublish date
+    queue an unpublish job for that date
```

## Call chain — changed control flow

Draw it with tree lines so who calls whom is visible, and note why a new call is there.

```diff
 ContentController.PublishContent
 ├── ContentService.Save
+│   └── ScheduledPublishService.QueueUnpublish   # new: queues the job on save
 └── ContentService.Publish
```

## Shallow file tree — changed responsibilities

Green for a new file, red only for a deleted one, and a context line with a `# changed:`
comment for a file whose job changed. Keep each file under its real folder.

```diff
 src/
 ├── Services/
+│   └── ScheduledPublishService.cs    # new: queues and cancels unpublish jobs
 ├── Notifications/
 │   └── ContentPublishedHandler.cs    # changed: also cancels a pending unpublish
-└── Jobs/LegacyUnpublishJob.cs        # removed: replaced by the service above
```

## Database table — a table or migration change

A column table, with the table and migration named above it, reads the same for any database
provider. Mark changed columns in the `Change` column; for a new table, leave it out.

**Table `myPackageScheduledUnpublish`** (migration `AddUnpublishDate`)

| Column | Type | Required | Change | Note |
|---|---|---|---|---|
| `Id` | int | yes | | Primary key |
| `ContentKey` | Guid | yes | | Links to the document |
| `UnpublishDate` | DateTime | yes | **New** | When the job runs |
| `CreatedBy` | int | no | **New** | User who scheduled it |

When the package maps the table with EF Core, diff the entity class instead if it says more
(a relationship, an owned type).

```diff
 public class ScheduledUnpublishEntity
 {
     public int Id { get; set; }
     public Guid ContentKey { get; set; }
+    public DateTime UnpublishDate { get; set; }
+    public int? CreatedBy { get; set; }
 }
```

## Lit component tree — changed backoffice UI

Only elements go in the tree; state and properties sit on their own lines under the element
that owns them, marked `state:` or `property:`. Put the element's file in a trailing comment.

```diff
 <my-package-workspace-view>                # client/src/workspace/workspace-view.element.ts
 │   state: _content
+│   state: _scheduledUnpublishDate
 └── <uui-box>
+    ├── <uui-input type="datetime-local">  # picks the unpublish date
+    └── <uui-button label="Clear">         # cancels a scheduled unpublish
```

Note state and package boundaries that matter to the change, not every attribute.

## Manifest / composer registration — a changed extension point

Umbraco-specific: most backoffice extensions and server-side pipeline hooks register through a
manifest entry or a `Composer`/`IComposer`, not through code a reviewer will stumble onto by
reading top to bottom. The backoffice registrations table below gives the overview; diff the
manifest only for what that table can't show, such as conditions, weight, or an override of a
core alias.

```diff
 {
   "type": "workspaceView",
   "alias": "MyPackage.WorkspaceView.ScheduledUnpublish",
   "name": "Scheduled Unpublish Workspace View",
   "js": "/App_Plugins/MyPackage/workspace-view.js",
   "conditions": [
     { "alias": "Umb.Condition.WorkspaceAlias", "match": "Umb.Workspace.Document" },
+    { "alias": "Umb.Condition.SectionAlias", "match": "Umb.Section.Content" }
   ]
 }
```

Show a composer change the same way:

```diff
 public class MyPackageComposer : IComposer
 {
     public void Compose(IUmbracoBuilder builder)
     {
         builder.AddNotificationHandler<ContentPublishedNotification, ContentPublishedHandler>();
+        builder.Services.AddSingleton<IScheduledPublishService, ScheduledPublishService>();
     }
 }
```

## Backoffice registrations — what was added to the backoffice

The readable summary of the manifest. One row per extension the PR adds, changes, or removes,
so a reviewer can see the whole footprint at once.

| Change | Type | Name | Where it appears |
|---|---|---|---|
| **New** | Workspace view | Scheduled unpublish | Document editor, as a tab after Info |
| **New** | Entity action | Cancel scheduled unpublish | "..." menu on a document in the tree |
| **Changed** | Dashboard | Publishing overview | Content section; now lists scheduled unpublishes |
| **Removed** | Dashboard | Legacy unpublish jobs | Was in the Settings section |

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
      "ScheduledUnpublish": {
        "CheckIntervalMinutes": 5,   // how often due jobs are run
        "KeepHistoryDays": 30        // how long finished jobs are kept
      }
    }
  }
}
```

A renamed, removed, or re-defaulted setting goes in a table instead, keyed by its full path:

| Setting | Before | After |
|---|---|---|
| `MyPackage:ScheduledUnpublish:CheckIntervalMinutes` | default `15` | default `5` |
| `MyPackage:UnpublishJobs:Enabled` | existed | **Removed**, always on now |

## Management API endpoints — new or changed routes

State the shared base path once, then one row per endpoint with only the rest of the route.
"Who can call it" is the authorization policy in plain words. Leave `Change` empty for an
unchanged route shown for context; drop the column when every route is new.

All routes start with `/umbraco/management/api/v1/my-package`.

| Change | Method | Route | Who can call it | What it does |
|---|---|---|---|---|
| | `GET` | `/scheduled-unpublish` | Users with access to Content | Lists scheduled unpublishes |
| **New** | `PUT` | `/scheduled-unpublish/{contentKey}` | Same | Sets or moves the date |
| **New** | `DELETE` | `/scheduled-unpublish/{contentKey}` | Same | Cancels it |

## Data structure / contract — a new or changed type

Show the complete shape when it's new or central to the change; diff it when adding to an
existing one, one member per line.

```diff
 public record ScheduledUnpublishRequest(
     Guid ContentKey,
+    DateTime UnpublishDate,
+    string? Reason);
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
- a data-model picture replaces the database table view, unless a column's exact type or
  constraint is the point

Text views that hold exact values stay, picture or not: the manifest or composer diff, the
backoffice registrations table, settings, API endpoints, a data contract, and a file tree.

## Rule of thumb

Tell the story in the order a reader needs it — a data structure or contract usually comes
before the code that consumes it, a table before the query that reads it. All views are
optional; use only the ones that carry weight for this specific PR.
