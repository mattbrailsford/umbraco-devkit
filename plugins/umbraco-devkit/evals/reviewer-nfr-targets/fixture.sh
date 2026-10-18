#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email eval@example.com && git config user.name eval
cat > CLAUDE.md <<'EOF'
# MyCompany.Newsletter

An Umbraco 17 package (C# plus a Lit backoffice client). Trunk branch: `main`. Supports SQL
Server and SQLite. Stores its own data with EF Core.

## Build & test

`dotnet build` and `dotnet test` from the repo root.

## Feature workflow

Each feature gets a plan folder at `docs/plans/<feature-slug>/`, created on `main`.
EOF
mkdir -p src/MyCompany.Newsletter/Subscriptions src/MyCompany.Newsletter/Export \
  tests/MyCompany.Newsletter.Tests/Export docs/plans/subscriber-export
cat > src/MyCompany.Newsletter/Subscriptions/Subscription.cs <<'EOF'
namespace MyCompany.Newsletter.Subscriptions;

public class Subscription
{
    public int Id { get; set; }
    public Guid MemberKey { get; set; }
    public int TopicId { get; set; }
    public Topic Topic { get; set; } = null!;
    public DateTime CreatedUtc { get; set; }
}
EOF
cat > src/MyCompany.Newsletter/Subscriptions/Topic.cs <<'EOF'
namespace MyCompany.Newsletter.Subscriptions;

public class Topic
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public bool Retired { get; set; }
}
EOF
cat > src/MyCompany.Newsletter/NewsletterComposer.cs <<'EOF'
namespace MyCompany.Newsletter;

public class NewsletterComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder)
    {
        builder.Services.AddSingleton<IMemberLookup, MemberLookup>();
    }
}
EOF
cat > docs/plans/subscriber-export/BRIEF.md <<'EOF'
# Brief

## Problem

Sites send newsletters from an external mailing tool. The tool should pull, every night, the
list of subscribed members and their topics through an API, using an Umbraco API user.

Constraints: the bigger customer sites have around 60,000 members, and several run on a
single small App Service plan that also serves the public site during the sync.

## Non-goals

- Webhooks or pushing changes to the tool.
EOF
cat > docs/plans/subscriber-export/ARCHITECTURE.md <<'EOF'
# Architecture

## Extension points
A Management API controller under `newsletter/export`, behind the Members section policy.

## Data model & persistence
None new. Reads `Subscription` and `Topic` through `NewsletterDbContext`, and members
through the package's `IMemberLookup` (one batched read per page).

## Connected systems
None. Read-only; no notifications, indexing or Deploy entities.

## Key decisions
- Keyset paging on `MemberKey` instead of skip/take, so late pages cost the same as early
  ones. Rejected: offset paging.
EOF
cat > docs/plans/subscriber-export/SPEC.md <<'EOF'
# Spec

## Management API surface

### `GET /umbraco/management/api/v1/newsletter/export/subscribers`

Query: `after` (Guid, optional: the `nextAfter` of the previous page) and `take` (int,
default 500, 1 to 500).

Response `200`: `{ "items": [{ "memberKey", "email", "topics": [{ "id", "name" }] }],
"nextAfter": Guid | null }`.

- Items are ordered by `memberKey`. A member appears once, with all non-retired topics.
- A member with only retired topics is left out.
- `nextAfter` is `null` on the last page.
- `take` outside 1 to 500, or an `after` that isn't a Guid: `400` `ProblemDetails`.
- No token: `401`. A user without Members section access: `403`.

## Frontend components

None.

## Non-functional targets

- A page at `take=500` returns in under 1 second at the 95th percentile with 60,000
  members and about 150,000 subscriptions, on SQL Server and on SQLite.
- A full export of 60,000 members, one page after another, finishes in under 5 minutes.
- Each request runs at most two queries on the package's tables plus one batched member
  read, whatever `take` is.
- Memory per request is bounded by `take`: nothing loads all subscriptions or all members.

> ASSUMPTION: the 1 second and 5 minute figures are mine, not from `BRIEF.md`. Confirm or
> replace them.
EOF
cat > docs/plans/subscriber-export/PLAN.md <<'EOF'
# Plan

- [x] 1. `SubscriberExportService`: keyset-paged read of members with non-retired topics, one batched member read per page. Integration tests on SQLite.
- [x] 2. `SubscriberExportController`: `GET newsletter/export/subscribers`, `take`/`after` validation, Members section policy. Tests for 400/401/403.
EOF
cat > docs/plans/subscriber-export/README.md <<'EOF'
# Subscriber export

1. [x] [BRIEF.md](./BRIEF.md) — Mailing tools pull a nightly list of subscribed members and topics.
2. [x] [ARCHITECTURE.md](./ARCHITECTURE.md) — A Management API controller with keyset paging over existing tables.
3. [x] [SPEC.md](./SPEC.md) — One paged GET endpoint, its validation, auth, and performance targets.
4. [x] [STORIES.md](./STORIES.md) — Two stories: export a page, walk every page.
5. [x] [PLAN.md](./PLAN.md) — Two tasks, service then controller.
6. [ ] [BUILD-LOG.md](./BUILD-LOG.md) — <pending>
EOF
git add -A && git commit -q -m "chore: subscriber-export plan"

# ---- the feature branch ----
cat > src/MyCompany.Newsletter/NewsletterComposer.cs <<'EOF'
namespace MyCompany.Newsletter;

public class NewsletterComposer : IComposer
{
    public void Compose(IUmbracoBuilder builder)
    {
        builder.Services.AddSingleton<IMemberLookup, MemberLookup>();
        builder.Services.AddScoped<ISubscriberExportService, SubscriberExportService>();
    }
}
EOF
cat > src/MyCompany.Newsletter/Export/SubscriberExportPage.cs <<'EOF'
namespace MyCompany.Newsletter.Export;

public sealed record ExportTopic(int Id, string Name);

public sealed record ExportSubscriber(Guid MemberKey, string Email, IReadOnlyList<ExportTopic> Topics);

public sealed record SubscriberExportPage(IReadOnlyList<ExportSubscriber> Items, Guid? NextAfter);
EOF
cat > src/MyCompany.Newsletter/Export/ISubscriberExportService.cs <<'EOF'
namespace MyCompany.Newsletter.Export;

public interface ISubscriberExportService
{
    Task<SubscriberExportPage> GetPageAsync(Guid? after, int take, CancellationToken cancellationToken = default);
}
EOF
cat > src/MyCompany.Newsletter/Export/SubscriberExportService.cs <<'EOF'
namespace MyCompany.Newsletter.Export;

internal sealed class SubscriberExportService : ISubscriberExportService
{
    private readonly IDbContextFactory<NewsletterDbContext> _dbFactory;
    private readonly IMemberLookup _memberLookup;

    public SubscriberExportService(IDbContextFactory<NewsletterDbContext> dbFactory, IMemberLookup memberLookup)
    {
        _dbFactory = dbFactory;
        _memberLookup = memberLookup;
    }

    public async Task<SubscriberExportPage> GetPageAsync(Guid? after, int take, CancellationToken cancellationToken = default)
    {
        await using var db = await _dbFactory.CreateDbContextAsync(cancellationToken);

        // Keyset paging: the next `take` member keys after the cursor that have a live topic.
        IQueryable<Guid> keys = db.Subscriptions
            .AsNoTracking()
            .Where(s => !s.Topic.Retired)
            .Select(s => s.MemberKey)
            .Distinct();
        if (after is { } cursor)
        {
            keys = keys.Where(k => k.CompareTo(cursor) > 0);
        }

        List<Guid> pageKeys = await keys.OrderBy(k => k).Take(take + 1).ToListAsync(cancellationToken);
        bool hasMore = pageKeys.Count > take;
        if (hasMore)
        {
            pageKeys.RemoveAt(pageKeys.Count - 1);
        }

        var rows = await db.Subscriptions
            .AsNoTracking()
            .Where(s => pageKeys.Contains(s.MemberKey) && !s.Topic.Retired)
            .Select(s => new { s.MemberKey, s.TopicId, s.Topic.Name })
            .ToListAsync(cancellationToken);

        IReadOnlyDictionary<Guid, string> emails = await _memberLookup.GetEmailsAsync(pageKeys, cancellationToken);

        var items = pageKeys
            .Where(emails.ContainsKey)
            .Select(k => new ExportSubscriber(
                k,
                emails[k],
                rows.Where(r => r.MemberKey == k).Select(r => new ExportTopic(r.TopicId, r.Name)).ToList()))
            .ToList();

        return new SubscriberExportPage(items, hasMore ? pageKeys[^1] : null);
    }
}
EOF
cat > src/MyCompany.Newsletter/Export/SubscriberExportController.cs <<'EOF'
namespace MyCompany.Newsletter.Export;

[ApiVersion("1.0")]
[VersionedApiBackOfficeRoute("newsletter/export")]
[ApiExplorerSettings(GroupName = "Newsletter")]
[Authorize(Policy = AuthorizationPolicies.SectionAccessMembers)]
public sealed class SubscriberExportController : ManagementApiControllerBase
{
    private const int MaxTake = 500;
    private readonly ISubscriberExportService _exportService;

    public SubscriberExportController(ISubscriberExportService exportService) => _exportService = exportService;

    [HttpGet("subscribers")]
    [ProducesResponseType(typeof(SubscriberExportPage), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> GetSubscribers(Guid? after, int take = MaxTake, CancellationToken cancellationToken = default)
    {
        if (take is < 1 or > MaxTake)
        {
            return BadRequest(new ProblemDetailsBuilder()
                .WithTitle("Invalid take")
                .WithDetail($"take must be between 1 and {MaxTake}.")
                .Build());
        }

        SubscriberExportPage page = await _exportService.GetPageAsync(after, take, cancellationToken);
        return Ok(page);
    }
}
EOF
cat > tests/MyCompany.Newsletter.Tests/Export/SubscriberExportServiceTests.cs <<'EOF'
namespace MyCompany.Newsletter.Tests.Export;

[TestFixture]
public class SubscriberExportServiceTests : SqliteNewsletterTestBase
{
    [Test]
    public async Task Walks_every_member_once_in_key_order()
    {
        SeedMembers(count: 30, topicsEach: 2);
        var service = CreateService();

        var seen = new List<Guid>();
        Guid? after = null;
        do
        {
            var page = await service.GetPageAsync(after, take: 7);
            seen.AddRange(page.Items.Select(i => i.MemberKey));
            after = page.NextAfter;
        }
        while (after is not null);

        Assert.That(seen, Has.Count.EqualTo(30));
        Assert.That(seen, Is.Unique);
        Assert.That(seen, Is.Ordered);
    }

    [Test]
    public async Task Leaves_out_retired_topics_and_members_with_only_retired_topics()
    {
        var live = SeedMember(topics: ["Events", "Research"], retired: ["Research"]);
        var gone = SeedMember(topics: ["Research"], retired: ["Research"]);
        var service = CreateService();

        var page = await service.GetPageAsync(null, take: 500);

        Assert.That(page.Items.Select(i => i.MemberKey), Does.Contain(live).And.Not.Contain(gone));
        Assert.That(page.Items.Single(i => i.MemberKey == live).Topics.Select(t => t.Name), Is.EqualTo(new[] { "Events" }));
    }

    [Test]
    public async Task Last_page_has_no_cursor()
    {
        SeedMembers(count: 3, topicsEach: 1);
        var page = await CreateService().GetPageAsync(null, take: 500);
        Assert.That(page.NextAfter, Is.Null);
    }
}
EOF
cat > tests/MyCompany.Newsletter.Tests/Export/SubscriberExportControllerTests.cs <<'EOF'
namespace MyCompany.Newsletter.Tests.Export;

[TestFixture]
public class SubscriberExportControllerTests : ManagementApiTestBase
{
    private const string Url = "/umbraco/management/api/v1/newsletter/export/subscribers";

    [TestCase(0)]
    [TestCase(501)]
    public async Task Take_out_of_range_is_400(int take)
    {
        var response = await AuthenticatedClient(memberSectionAccess: true).GetAsync($"{Url}?take={take}");
        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.BadRequest));
    }

    [Test]
    public async Task No_token_is_401()
    {
        var response = await Client.GetAsync(Url);
        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.Unauthorized));
    }

    [Test]
    public async Task No_members_section_access_is_403()
    {
        var response = await AuthenticatedClient(memberSectionAccess: false).GetAsync(Url);
        Assert.That(response.StatusCode, Is.EqualTo(HttpStatusCode.Forbidden));
    }
}
EOF
git add -A
git diff --cached main > CHANGE.diff
git reset -q
