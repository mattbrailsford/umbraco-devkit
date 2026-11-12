#!/usr/bin/env bash
set -euo pipefail

# A small stand-in for the CMS clone, with the current release and the target's first RC.
cms="$PWD/.cms"
mkdir -p "$cms/src/Umbraco.Core/DeliveryApi" "$cms/src/Umbraco.Core/Webhooks"
git -C "$cms" init -q
git -C "$cms" config user.email cms@example.com
git -C "$cms" config user.name CMS
git -C "$cms" remote add origin https://github.com/umbraco/Umbraco-CMS.git
cat > "$cms/Directory.Build.props" <<'XML'
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
</Project>
XML
cat > "$cms/src/Umbraco.Core/DeliveryApi/IApiContentResponseBuilder.cs" <<'CS'
using Umbraco.Cms.Core.Models.DeliveryApi;
using Umbraco.Cms.Core.Models.PublishedContent;

namespace Umbraco.Cms.Core.DeliveryApi;

public interface IApiContentResponseBuilder
{
    IApiContentResponse? Build(IPublishedContent content);
}
CS
cat > "$cms/src/Umbraco.Core/Webhooks/WebhookFiringService.cs" <<'CS'
namespace Umbraco.Cms.Core.Webhooks;

public class WebhookFiringService
{
    public void Fire(string eventAlias) { }
}
CS
git -C "$cms" add -A
git -C "$cms" commit -qm "Release 18.4.0"
git -C "$cms" tag release-18.4.0

sed -i.bak 's/net10.0/net11.0/' "$cms/Directory.Build.props" && rm "$cms/Directory.Build.props.bak"
git -C "$cms" commit -qam "Bump to .NET 11 (#99001)"
printf '\n// Retry on timeout\n' >> "$cms/src/Umbraco.Core/Webhooks/WebhookFiringService.cs"
git -C "$cms" commit -qam "Webhooks: retry on timeout (#99210)"
git -C "$cms" tag release-19.0.0-rc1

# GitHub can't be reached from the eval, so a stand-in `gh` answers from recorded data: a few
# hundred PRs, so a broad listing is as noisy as the real repo. The data is stored packed, so
# reading the stand-in or its data doesn't hand over the answer.
# rc1 is the newest 19 release. Three PRs labelled release/19.0.0 are still open: #99870
# changes an interface the package implements but isn't labelled breaking, #99881 is labelled
# breaking in an area the package never uses, #99902 is UI only.
sha_of() { git -C "$cms" log --format=%H --grep="(#$1)" -1 release-19.0.0-rc1; }
mkdir -p .tools
python3 - "$(sha_of 99001)" "$(sha_of 99210)" <<'PY'
import base64, json, random, zlib
sha_dotnet, sha_webhooks = __import__("sys").argv[1:3]
rnd = random.Random(19)
areas = [("Block Grid", "src/Umbraco.Web.UI.Client/src/packages/block/block-grid/", "area/frontend"),
         ("Tiptap", "src/Umbraco.Web.UI.Client/src/packages/tiptap/", "area/frontend"),
         ("Members", "src/Umbraco.Core/Services/MemberService.cs", "area/backend"),
         ("Media", "src/Umbraco.Infrastructure/Media/", "area/backend"),
         ("Search", "src/Umbraco.Examine.Lucene/", "area/backend"),
         ("Users", "src/Umbraco.Web.UI.Client/src/packages/user/", "area/frontend"),
         ("Templates", "src/Umbraco.Web.UI.Client/src/packages/templating/", "area/frontend"),
         ("Localization", "src/Umbraco.Web.UI.Client/src/assets/lang/", "area/frontend"),
         ("Content Types", "src/Umbraco.Core/Services/ContentTypeService.cs", "area/backend"),
         ("Webhooks", "src/Umbraco.Core/Webhooks/", "area/backend"),
         ("Dictionary", "src/Umbraco.Web.UI.Client/src/packages/dictionary/", "area/frontend"),
         ("Acceptance tests", "tests/Umbraco.Tests.AcceptanceTest/", "area/test")]
verbs = ["fix sorting", "fix validation message", "improve loading state", "tidy up styles",
         "handle empty values", "add missing translations", "fix paging", "speed up lookup",
         "fix focus after save", "clean up unused code", "fix culture fallback", "add tests"]
cats = ["category/bug", "category/ux", "category/ui", "category/performance", "category/localization"]
prs = []
for n in range(99300, 99700):
    area, path, alabel = rnd.choice(areas)
    state = "OPEN" if rnd.random() < 0.25 else "MERGED"
    rel = rnd.choice(["release/18.5.0", "release/18.5.0", "release/19.0.0", "release/no-notes", None])
    labels = [alabel, rnd.choice(cats)] + ([rel] if rel else [])
    base = "v19/dev" if rel == "release/19.0.0" else rnd.choice(["main", "v18/dev"])
    if state == "OPEN" and rel == "release/19.0.0":
        rel, labels, base = None, [alabel, rnd.choice(cats)], "main"  # open ones aren't planned
    prs.append({"number": n, "title": f"{area}: {rnd.choice(verbs)}", "state": state,
                "baseRefName": base, "labels": [{"name": l} for l in labels],
                "mergedAt": None if state == "OPEN" else f"2026-{rnd.randint(4,10):02d}-{rnd.randint(1,28):02d}T10:00:00Z",
                "mergeCommit": None if state == "OPEN" else {"oid": "%040x" % rnd.getrandbits(160)},
                "body": "", "files": [{"path": path + ("" if path.endswith((".cs", ".ts")) else "index.ts")}]})
for n in range(99950, 100120):  # newer than the ones that matter, so a default listing shows only these
    area, path, alabel = rnd.choice(areas)
    prs.append({"number": n, "title": f"{area}: {rnd.choice(verbs)}", "state": rnd.choice(["OPEN", "MERGED", "MERGED"]),
                "baseRefName": "main", "labels": [{"name": alabel}, {"name": rnd.choice(cats)}],
                "mergedAt": "2026-11-0%dT10:00:00Z" % rnd.randint(4, 9), "mergeCommit": {"oid": "%040x" % rnd.getrandbits(160)},
                "body": "", "files": [{"path": path + ("" if path.endswith((".cs", ".ts")) else "index.ts")}]})
    if prs[-1]["state"] == "OPEN":
        prs[-1]["mergedAt"] = prs[-1]["mergeCommit"] = None
prs += [
    {"number": 99001, "title": "Bump to .NET 11", "baseRefName": "v19/dev", "state": "MERGED",
     "mergedAt": "2026-08-02T10:00:00Z", "body": "",
     "labels": [{"name": "category/breaking"}, {"name": "release/19.0.0"}],
     "mergeCommit": {"oid": sha_dotnet}, "files": [{"path": "Directory.Build.props"}]},
    {"number": 99210, "title": "Webhooks: retry on timeout", "baseRefName": "v19/dev", "state": "MERGED",
     "mergedAt": "2026-09-12T10:00:00Z", "body": "",
     "labels": [{"name": "category/bug"}, {"name": "release/19.0.0"}],
     "mergeCommit": {"oid": sha_webhooks}, "files": [{"path": "src/Umbraco.Core/Webhooks/WebhookFiringService.cs"}]},
    {"number": 99870, "title": "Delivery API: build content responses asynchronously",
     "baseRefName": "v19/dev", "state": "OPEN", "mergedAt": None, "mergeCommit": None,
     "labels": [{"name": "category/api"}, {"name": "area/backend"}, {"name": "release/19.0.0"}],
     "body": "Replaces IApiContentResponseBuilder.Build with BuildAsync so builders can await property value conversion.",
     "files": [{"path": "src/Umbraco.Core/DeliveryApi/IApiContentResponseBuilder.cs"},
               {"path": "src/Umbraco.Infrastructure/DeliveryApi/ApiContentResponseBuilder.cs"},
               {"path": "src/Umbraco.Cms.Api.Delivery/Controllers/Content/ByIdContentApiController.cs"}]},
    {"number": 99881, "title": "Webhooks: remove the synchronous firing service",
     "baseRefName": "v19/dev", "state": "OPEN", "mergedAt": None, "mergeCommit": None,
     "labels": [{"name": "category/breaking"}, {"name": "area/backend"}, {"name": "release/19.0.0"}],
     "body": "Removes WebhookFiringService.Fire in favour of the background queue.",
     "files": [{"path": "src/Umbraco.Core/Webhooks/WebhookFiringService.cs"}]},
    {"number": 99902, "title": "Entity Frame: make entity frame styles secondary to base class",
     "baseRefName": "v19/dev", "state": "OPEN", "mergedAt": None, "mergeCommit": None,
     "labels": [{"name": "category/ui"}, {"name": "area/frontend"}, {"name": "release/19.0.0"}],
     "body": "Styling only.",
     "files": [{"path": "src/Umbraco.Web.UI.Client/src/packages/core/entity-item/entity-item-ref/entity-item-ref-frame.mixin.ts"}]},
]
prs.sort(key=lambda p: -p["number"])
data = {"prs": prs, "commits": {sha_dotnet: 99001, sha_webhooks: 99210}}
open(".tools/gh-cache.bin", "wb").write(base64.b64encode(zlib.compress(json.dumps(data).encode())))
PY
cat > .tools/gh <<'PYGH'
#!/usr/bin/env python3
"""Offline gh: answers umbraco/Umbraco-CMS queries from a local cache."""
import base64, json, os, re, shutil, subprocess, sys, zlib

here = os.path.dirname(os.path.abspath(__file__))
data = json.loads(zlib.decompress(base64.b64decode(open(os.path.join(here, "gh-cache.bin"), "rb").read())))
args = sys.argv[1:]

def opt(*names):
    for name in names:
        if name in args:
            return args[args.index(name) + 1]
    return None

def emit(value, default_fields):
    q = opt("-q", "--jq")
    if opt("--json") is None:
        for p in value if isinstance(value, list) else [value]:
            print(f"#{p['number']}\t{p['title']}\t{p['baseRefName']}\t{p['state']}")
        return
    text = json.dumps(value)
    if q and shutil.which("jq"):
        sys.stdout.write(subprocess.run(["jq", "-r", q], input=text, capture_output=True, text=True).stdout)
    else:
        print(text)

if args[:2] == ["pr", "list"]:
    search = (opt("--search", "-S") or "").lower()
    state = (opt("--state", "-s") or "open").lower()
    if "is:open" in search: state = "open"
    if "is:merged" in search: state = "merged"
    if "is:closed" in search: state = "closed"
    labels = [l for l in [opt("--label", "-l")] if l] + re.findall(r'label:"?([\w/.-]+)', search)
    base = opt("--base", "-B")
    rows = [p for p in data["prs"]
            if (state == "all" or p["state"].lower() == state or (state == "closed" and p["state"] == "MERGED"))
            and all(l.lower() in [x["name"].lower() for x in p["labels"]] for l in labels)
            and (base is None or p["baseRefName"] == base)]
    emit(rows[: int(opt("--limit", "-L") or 30)], None)
elif args[:2] == ["release", "list"]:
    print("release-19.0.0-rc1\tPre-release\trelease-19.0.0-rc1\t2026-11-03T10:00:00Z")
    print("release-18.4.0\tLatest\trelease-18.4.0\t2026-10-14T10:00:00Z")
elif args[:2] == ["release", "view"]:
    print("title:\trelease-19.0.0-rc1\n--\n## 💥 Breaking Changes\n"
          "* Bump to .NET 11 by @cms-team in #99001\n\n"
          "## 🐛 Bug fixes\n* Webhooks: retry on timeout by @cms-team in #99210\n")
elif args[:2] in (["pr", "view"], ["pr", "diff"]):
    n = int(re.sub(r"\D", "", args[2]))
    pr = next((p for p in data["prs"] if p["number"] == n), None)
    if pr is None:
        print(f"could not find pull request #{n}", file=sys.stderr); sys.exit(1)
    if args[1] == "diff":
        print("\n".join(f["path"] for f in pr["files"]))
    else:
        emit(pr, None)
elif args and args[0] == "api":
    m = re.search(r"commits/([0-9a-f]+)/pulls", " ".join(args))
    if m and m.group(1) in data["commits"]:
        emit([{"number": data["commits"][m.group(1)]}], None) if opt("--json") else print(json.dumps([{"number": data["commits"][m.group(1)]}]))
    else:
        print("[]")
else:
    print("not available offline", file=sys.stderr); sys.exit(1)
PYGH
chmod +x .tools/gh

# The package: a Delivery API decorator that adds stock levels to content responses.
P=src/Umbraco.Community.StockLevels
mkdir -p $P/DeliveryApi
cat > CLAUDE.md <<'MD'
# Umbraco.Community.StockLevels

An Umbraco 18 package: tracks stock per product and adds it to Delivery API responses.
One version line: `main`. The package version follows the CMS major (18.x for Umbraco 18).
MD
cat > CLAUDE.local.md <<MD
- Umbraco CMS source: $cms
MD
cat > $P/Umbraco.Community.StockLevels.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Version>18.2.0</Version>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Api.Delivery" Version="[18.4.0, 19.0.0)" />
  </ItemGroup>
</Project>
XML
cat > $P/DeliveryApi/StockContentResponseBuilder.cs <<'CS'
using Umbraco.Cms.Core.DeliveryApi;
using Umbraco.Cms.Core.Models.DeliveryApi;
using Umbraco.Cms.Core.Models.PublishedContent;

namespace Umbraco.Community.StockLevels.DeliveryApi;

// Decorates the CMS builder to add a "stock" property to product responses.
internal sealed class StockContentResponseBuilder : IApiContentResponseBuilder
{
    private readonly IApiContentResponseBuilder _inner;
    private readonly IStockService _stock;

    public StockContentResponseBuilder(IApiContentResponseBuilder inner, IStockService stock)
    {
        _inner = inner;
        _stock = stock;
    }

    public IApiContentResponse? Build(IPublishedContent content)
    {
        var response = _inner.Build(content);
        if (response is not null && content.ContentType.Alias == "product")
        {
            response.Properties["stock"] = _stock.GetLevel(content.Key);
        }

        return response;
    }
}
CS
