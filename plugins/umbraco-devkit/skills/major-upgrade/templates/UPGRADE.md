# Upgrade to Umbraco [target major]

From `[current exact CMS version]` to `[target exact CMS version]` (tag `release-[x.y.z]`).
Branch `[branch]`, cut from `[base branch]`.

**Targets CMS release:** `[release-x.y.z-rc1]`. [Updated on each refresh. While this is a
pre-release, the package's own version is a pre-release too.]

## Inventory

What the target major changes that this project actually uses. One entry per change, each
with its source (CMS PR, release tag, obsolete warning, or docs page), the CMS release it
first appeared in, and where it hits the project. A list, not a table: sources and paths are
too long for table cells on a phone.

- **[.NET 10 → .NET 11]** ([rc1])\
  Source: [`release-19.0.0-rc1:Directory.Build.props`]\
  Hits: [every project]
- **[EF Core 10.0.10 → 11.0.2, to match the CMS]** ([rc1])\
  Source: [`release-19.0.0-rc1:Directory.Packages.props`]\
  Hits: [`Directory.Packages.props`]
- **[`UmbracoApiController` removed]** ([rc1])\
  Source: [umbraco/Umbraco-CMS#12345]\
  Hits: [`src/Api/ProductsController.cs`]
- **[`IFooService.Get` obsolete, use `GetAsync`]** ([rc1])\
  Source: [CS0618 on `release-19.0.0-rc1`]\
  Hits: [`src/Services/Bar.cs:40`]

## Third-party dependencies

Shipped dependencies offered in inventory step 10, and what was picked. Forced bumps are
marked; they go in the main bump task.

- **[JsonSchema.Net.Generation]** [5.1.1] → [7.4.0]. [Picked / Not picked].\
  Breaks: [`JsonSchema` in `IStepType`; consumers see it]

## Stopgaps

`TODO(stopgap):` markers offered in inventory step 11, and what was picked.

- **[`GetLevel` returns -1 for untracked stock]**. [Picked / Not picked].\
  Where: [`src/Services/IStockService.cs:12`]\
  Proper fix: [return `int?`]. [Breaking for consumers / Not breaking].

## Blockers

[Dependencies with no release for the target major yet, or "None".]

## Tasks

Each task ends in a green build.

- [ ] [Replace obsolete usages flagged on the current version, before the bump]
- [ ] [Bump target framework and Umbraco packages; fix compile errors]
- [ ] [Replace APIs the target release made obsolete]
- [ ] [Handle behavior changes]
- [ ] [Bump `@umbraco-cms/backoffice`; fix the client]
- [ ] [Bump <shipped dependency or family> to <version>, one task each]
- [ ] [Remove this package's own code scheduled for removal in this version]
- [ ] [Proper fix for <stopgap>, one task each]
- [ ] [Update compatibility markers]

## Decisions

[Dated one-line entries for choices the inventory left open.]

## Breaking changes for consumers

[Changes to this package's own public API or manifest aliases: ones the upgrade forced, the
package's own deprecated code removed in this version, and dependency bumps consumers will
see. Or "None".]

## Follow-ups

[Things found along the way that the upgrade didn't need: obsolete APIs whose replacement
isn't in every CMS version the branch builds against, shipped dependency majors not picked,
stopgaps not picked, refactors, dropping an old major.]

## Log

[One line per task: commit SHA, what was verified.]
