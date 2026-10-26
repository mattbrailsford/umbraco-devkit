# Text views

A text view shows structure in a code block or a short table: a file tree, a call chain, a
component tree, a table's columns, a setting, a route, a type. Use one where it says more
exactly than a picture or a paragraph would, usually because the exact name, type or value
is the point.

## Contents

- Picture or text view
- Plan or change
- Reading rules for every view
- Pseudocode — an algorithm or business rule
- Call chain — who calls whom
- Shallow file tree — where code lives
- Database table — columns and types
- Lit component tree — how a backoffice screen is built
- Manifest / composer registration — how an extension is registered
- Backoffice registrations — what appears in the backoffice
- Settings — configuration
- Management API endpoints — routes
- Data structure / contract — a type's shape

## Picture or text view

A picture shows how parts connect; a text view holds exact names and values. When a document
has a picture of an idea, it replaces the text view that tells the same story:

- a flow or sequence picture replaces the call chain and the pseudocode
- a component-tree picture replaces the Lit component tree
- a data-model picture replaces the database table, unless a column's exact type or
  constraint is the point

Views that hold exact values stay, picture or not: the manifest or composer diff, the
backoffice registrations table, settings, API endpoints, a data contract, and a file tree.

A tree drawn with tree lines (`├──`, `└──`) is a text view. Boxes joined by arrows
(`A ──▶ B`) are a picture, and are drawn as an SVG.

## Plan or change

- **In a plan or doc** (`ARCHITECTURE.md`, `SPEC.md`, a docs page), show the shape as it will
  be, in its own language (`csharp`, `jsonc`, `text` for a tree), with no `+` or `-`.
- **In a change** (a PR description), show it as a `diff` against the old shape when the
  surrounding shape already exists. Show the whole block, undiffed, when most of it is new,
  or when trimming context would hide who owns what or in what order things happen.

The examples below show the change form; drop the `+` and `-` for a plan.

## Reading rules for every view

- In a `diff`, red means removed. Never remove a line and add it back just to annotate it: a reader sees
  red and thinks it's gone. Leave a changed line as context and say what changed in a trailing
  comment (`# changed: ...`).
- Put one item per line (a parameter, a property, a child), so a diff marks only what was
  added instead of turning a whole rewritten line red and green.
- A table inside a `diff` block renders as raw pipes. Show a changed set of rows with a
  `Change` column (**New**, **Changed**, **Removed**) instead.
- Keep lines under about 90 characters; wider ones scroll sideways on GitHub.
- Tables follow `plain-writing`'s "Fit a narrow screen": four columns at most, short cells.
  A view whose rows need more becomes a list, with **New**, **Changed** or **Removed** at
  the start of each line.

## Pseudocode — an algorithm or business rule

Write the steps in plain words, not code.

```diff
 when content is published
   save content
+  if content has a scheduled unpublish date
+    queue an unpublish job for that date
```

## Call chain — who calls whom

Draw it with tree lines so who calls whom is visible, and note why a new call is there.

```diff
 ContentController.PublishContent
 ├── ContentService.Save
+│   └── ScheduledPublishService.QueueUnpublish   # new: queues the job on save
 └── ContentService.Publish
```

## Shallow file tree — where code lives

Keep each file under its real folder, with its job in a trailing comment. In a change: green
for a new file, red only for a deleted one, and a context line with a `# changed:` comment for
a file whose job changed.

```diff
 src/
 ├── Services/
+│   └── ScheduledPublishService.cs    # new: queues and cancels unpublish jobs
 ├── Notifications/
 │   └── ContentPublishedHandler.cs    # changed: also cancels a pending unpublish
-└── Jobs/LegacyUnpublishJob.cs        # removed: replaced by the service above
```

## Database table — columns and types

A column table, with the table and migration named above it, reads the same for any database
provider. Mark changed columns in the `Change` column; for a new table, leave it out.

**Table `myPackageScheduledUnpublish`** (migration `AddUnpublishDate`)

| Column | Type | Change | Note |
|---|---|---|---|
| `Id` | `int` | | Primary key |
| `ContentKey` | `Guid` | | Links to the document |
| `UnpublishDate` | `DateTime` | **New** | When the job runs |
| `CreatedBy` | `int?` | **New** | User who scheduled it |

A `?` on the type means the column allows nulls. Keep the table to these four columns so it
fits a phone (`plain-writing`'s "Fit a narrow screen").

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

## Lit component tree — how a backoffice screen is built

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

## Manifest / composer registration — how an extension is registered

Umbraco-specific: most backoffice extensions and server-side pipeline hooks register through a
manifest entry or a `Composer`/`IComposer`, not through code a reader will stumble onto by
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

## Backoffice registrations — what appears in the backoffice

The readable summary of the manifest. One row per extension, so a reader can see the whole
footprint at once. In a change, the `Change` column says what the change adds, changes or
removes; in a plan, leave the column out.

| Change | Type | Name | Where it appears |
|---|---|---|---|
| **New** | Workspace view | Scheduled unpublish | Document editor, as a tab after Info |
| **New** | Entity action | Cancel scheduled unpublish | "..." menu on a document in the tree |
| **Changed** | Dashboard | Publishing overview | Content section; now lists scheduled unpublishes |
| **Removed** | Dashboard | Legacy unpublish jobs | Was in the Settings section |

Use the editor-facing name and place, not the alias. Leave out extensions with no visible
footprint (a condition, a repository) unless they're the point of the change.

## Settings — configuration

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

A renamed, removed, or re-defaulted setting goes in a list instead, its full path on one line
and the change under it. A full path is too long for a table cell on a phone.

- `MyPackage:ScheduledUnpublish:CheckIntervalMinutes`\
  Default `15` → `5`
- `MyPackage:UnpublishJobs:Enabled`\
  **Removed**, always on now

## Management API endpoints — routes

State the shared base path once, and who can call the routes when it's the same for all of
them, in plain words from the authorization policy. Then pick the depth the reader needs.
Both are lists, not tables: five columns of routes don't fit a phone.

**Summary**, for an overview such as a PR: one bullet per endpoint, the method and the rest of
the route in code, **New** or **Changed** in front unless every route is new, then what it
does. A route that differs in who can call it says so on its own line.

All routes start with `/umbraco/management/api/v1/my-package`. Callers need access to the
Content section.

- `GET /scheduled-unpublish`: lists scheduled unpublishes
- **New** `PUT /scheduled-unpublish/{contentKey}`: sets or moves the date
- **New** `DELETE /scheduled-unpublish/{contentKey}`: cancels it

**Contract**, for a spec a test is written from: the method and route in bold code, what it
takes in a few words, then one bullet per status code with its body or its condition.

**`PUT /scheduled-unpublish/{contentKey}`** takes `{ unpublishDate, reason? }`.
- **204** set or moved
- **400** `ProblemDetails` when the date is in the past
- **404** no such document

## Data structure / contract — a type's shape

Show the complete shape when it's new or central to the change; diff it when adding to an
existing one, one member per line.

```diff
 public record ScheduledUnpublishRequest(
     Guid ContentKey,
+    DateTime UnpublishDate,
+    string? Reason);
```
