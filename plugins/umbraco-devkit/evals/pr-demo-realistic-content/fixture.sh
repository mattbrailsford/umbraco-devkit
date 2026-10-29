#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'MD'
# Umbraco.Community.TagCloud

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`.

## Build & test

- `dotnet test` runs the unit tests.
- Start the demo site with `dotnet run --project demo/TagCloud.Demo`. Its port comes from
  `git wdp-port`. The backoffice login is in `demo/TagCloud.Demo/appsettings.Development.json`
  under `Umbraco:CMS:Unattended`.
- The demo site is "Northside Roasters", a small coffee roastery: a home page and a blog with
  four tagged posts, in its SQLite database. The worktree hook copies it into each new
  worktree.
MD
git add -A && git commit -qm "chore: initial"

W=worktrees/tagged-posts-dashboard
mkdir -p $W/src/Umbraco.Community.TagCloud/Controllers $W/src/Umbraco.Community.TagCloud/Client/src
mkdir -p $W/demo/TagCloud.Demo/umbraco/Data
cp CLAUDE.md $W/
cat > $W/demo/TagCloud.Demo/appsettings.json <<'JSON'
{
  "ConnectionStrings": {
    "umbracoDbDSN": "Data Source=|DataDirectory|/Umbraco.sqlite.db;Cache=Shared;Foreign Keys=True;Pooling=True",
    "umbracoDbDSN_ProviderName": "Microsoft.Data.Sqlite"
  }
}
JSON
printf 'SQLite format 3\0' > $W/demo/TagCloud.Demo/umbraco/Data/Umbraco.sqlite.db
cat > $W/src/Umbraco.Community.TagCloud/Controllers/TaggedPostsController.cs <<'CS'
using Microsoft.AspNetCore.Mvc;
using Umbraco.Cms.Core.Services;

namespace Umbraco.Community.TagCloud.Controllers;

[ApiExplorerSettings(GroupName = "Tag Cloud")]
public class TaggedPostsController(ITagService tagService, IContentService contentService)
    : TagCloudControllerBase
{
    private const int PageSize = 10;

    [HttpGet("tagged-posts")]
    public IActionResult Get(string tag, int page = 1)
    {
        var ids = tagService.GetTaggedContentByTag(tag).Select(e => e.EntityId).ToArray();
        var posts = contentService.GetByIds(ids)
            .OrderByDescending(c => c.UpdateDate)
            .Skip((page - 1) * PageSize).Take(PageSize)
            .Select(c => new { c.Key, c.Name, c.UpdateDate });
        return Ok(new { total = ids.Length, items = posts });
    }
}
CS
cat > $W/src/Umbraco.Community.TagCloud/Client/src/tagged-posts-dashboard.element.ts <<'TS'
import { html, customElement, state } from '@umbraco-cms/backoffice/external/lit';
import { UmbLitElement } from '@umbraco-cms/backoffice/lit-element';

// Content section dashboard: pick a tag, see the posts using it, 10 per page.
@customElement('tag-cloud-tagged-posts-dashboard')
export class TaggedPostsDashboardElement extends UmbLitElement {
  @state() private _tag = '';
  @state() private _page = 1;

  override render() {
    return html`<uui-box headline="Posts by tag">
      <uui-input label="Tag" .value=${this._tag}></uui-input>
      <uui-table><!-- name, last updated --></uui-table>
      <uui-pagination .current=${this._page}></uui-pagination>
    </uui-box>`;
  }
}
TS
echo "$(pwd)                                   0a1b2c3 [main]" > WORKTREES.txt
echo "$(pwd)/worktrees/tagged-posts-dashboard  9f8e7d6 [tagged-posts-dashboard]" >> WORKTREES.txt
