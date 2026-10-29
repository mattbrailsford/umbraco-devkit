#!/usr/bin/env bash
set -euo pipefail

# A small stand-in for the CMS clone, with the two release tags.
cms="$PWD/.cms"
mkdir -p "$cms/src/Umbraco.Core/PropertyEditors" "$cms/src/Umbraco.Core/Services"
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
cat > "$cms/src/Umbraco.Core/PropertyEditors/PropertyValueConverterBase.cs" <<'CS'
using Umbraco.Cms.Core.Models.PublishedContent;

namespace Umbraco.Cms.Core.PropertyEditors;

public abstract class PropertyValueConverterBase : IPropertyValueConverter
{
    public virtual bool IsConverter(IPublishedPropertyType propertyType) => false;

    public virtual Type GetPropertyValueType(IPublishedPropertyType propertyType) => typeof(object);

    public virtual object? ConvertSourceToIntermediate(
        IPublishedElement owner,
        IPublishedPropertyType propertyType,
        object? source,
        bool preview)
        => source;

    public virtual object? ConvertIntermediateToObject(
        IPublishedElement owner,
        IPublishedPropertyType propertyType,
        PropertyCacheLevel referenceCacheLevel,
        object? inter,
        bool preview)
        => inter;
}
CS
cat > "$cms/src/Umbraco.Core/Services/ContentService.cs" <<'CS'
namespace Umbraco.Cms.Core.Services;

public class ContentService
{
    public int Count() => 0;
}
CS
git -C "$cms" add -A
git -C "$cms" commit -qm "Release 17.6.1"
git -C "$cms" tag release-17.6.1

sed -i.bak 's/net10.0/net11.0/' "$cms/Directory.Build.props" && rm "$cms/Directory.Build.props.bak"
git -C "$cms" commit -qam "Bump to .NET 11 (#99001)"

# A year of unrelated work, so the change below is one commit among many.
areas="Cache Configuration Delivery Events Hosting Logging Mapping Media Members Models Notifications Persistence Routing Scoping Security Sync Telemetry Templates Webhooks"
n=0
while read -r area; do
  mkdir -p "$cms/src/Umbraco.Core/$area"
  for i in 1 2 3 4 5 6 7 8; do
    n=$((n + 1))
    f="$cms/src/Umbraco.Core/$area/${area}Handler$i.cs"
    if [ -f "$f" ]; then :; else
      printf 'namespace Umbraco.Cms.Core.%s;\n\npublic class %sHandler%s\n{\n    public void Handle() { }\n}\n' "$area" "$area" "$i" > "$f"
    fi
    printf '\n// Revision %s\n' "$n" >> "$f"
    git -C "$cms" add -A
    git -C "$cms" commit -qm "$area: improve handler $i (#$((98000 + n)))"
  done
done <<AREAS
$(printf '%s\n' $areas)
AREAS

python3 - "$cms/src/Umbraco.Core/PropertyEditors/PropertyValueConverterBase.cs" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("""        object? source,
        bool preview)
        => source;""", """        object? source,
        string? culture,
        bool preview)
        => source;""")
open(p, "w").write(s)
PY
printf '\n// Revision culture\n' >> "$cms/src/Umbraco.Core/Routing/RoutingHandler3.cs"
git -C "$cms" commit -qam "Property editors: variant-aware conversion pipeline (#99412)"

cat > "$cms/src/Umbraco.Core/Services/ContentService.cs" <<'CS'
namespace Umbraco.Cms.Core.Services;

public class ContentService
{
    public int Count() => 0;

    public int CountPublished() => 0;
}
CS
git -C "$cms" commit -qam "Content service: add CountPublished (#99530)"
git -C "$cms" tag release-18.0.0

# GitHub can't be reached from the eval, so a stand-in `gh` answers from recorded data. Like
# the real thing, the `category/breaking` label and the release notes cover only some breaks:
# #99412 is in neither.
sha_of() { git -C "$cms" log --format=%H --grep="(#$1)" -1 release-18.0.0; }
mkdir -p .tools
cat > .tools/gh-data.json <<JSON
{
  "breaking": [
    {"number": 99001, "title": "Bump to .NET 11", "baseRefName": "v18/dev",
     "mergedAt": "2026-03-02T10:00:00Z", "labels": [{"name": "category/breaking"}],
     "mergeCommit": {"oid": "$(sha_of 99001)"}},
    {"number": 99530, "title": "Content service: add CountPublished", "baseRefName": "v18/dev",
     "mergedAt": "2026-05-20T10:00:00Z", "labels": [{"name": "category/breaking"}],
     "mergeCommit": {"oid": "$(sha_of 99530)"}}
  ],
  "commits": {"$(sha_of 99412)": 99412, "$(sha_of 99001)": 99001, "$(sha_of 99530)": 99530},
  "release": "release-18.0.0"
}
JSON
cat > .tools/gh <<'PYGH'
#!/usr/bin/env python3
"""Stand-in for gh with recorded umbraco/Umbraco-CMS data."""
import json, os, re, shutil, subprocess, sys

data = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "gh-data.json")))
args = sys.argv[1:]

def opt(name):
    return args[args.index(name) + 1] if name in args else None

def out(value):
    q = opt("-q") or opt("--jq")
    text = json.dumps(value)
    if q and shutil.which("jq"):
        sys.stdout.write(subprocess.run(["jq", "-r", q], input=text, capture_output=True, text=True).stdout)
    else:
        print(text)

if args[:2] == ["pr", "list"]:
    label = opt("--label") or ""
    search = opt("--search") or ""
    out(data["breaking"] if "category/breaking" in label + search else [])
elif args[:2] == ["release", "list"]:
    print(f"{data['release']}\tLatest\t{data['release']}\t2026-06-01T10:00:00Z")
elif args[:2] == ["release", "view"]:
    print(f"title:\t{data['release']}\n--\n## 💥 Breaking Changes\n"
          "* Bump to .NET 11 by @cms-team in #99001\n"
          "* Content service: add CountPublished by @cms-team in #99530\n\n"
          "## 🚀 New features\n* Webhooks: improve handler 8 by @cms-team in #98152\n")
elif args[:2] == ["pr", "view"]:
    n = int(re.sub(r"\D", "", args[2]))
    pr = next((p for p in data["breaking"] if p["number"] == n), None)
    if pr is None:
        print(f"no recorded data for #{n}", file=sys.stderr); sys.exit(1)
    out(pr)
elif args and args[0] == "api":
    m = re.search(r"commits/([0-9a-f]+)/pulls", " ".join(args))
    if m and m.group(1) in data["commits"]:
        out([{"number": data["commits"][m.group(1)]}])
    else:
        print("no recorded data for this request", file=sys.stderr); sys.exit(1)
else:
    print("no recorded data for this command", file=sys.stderr); sys.exit(1)
PYGH
chmod +x .tools/gh

# The package.
mkdir -p src/Umbraco.Community.PriceBadge/Converters
cat > CLAUDE.md <<'MD'
# Umbraco.Community.PriceBadge

An Umbraco 17 package: a property editor that stores a price and shows it as a badge.
One version line: `main`. The package version follows the CMS major (17.x for Umbraco 17).
MD
cat > CLAUDE.local.md <<MD
- Umbraco CMS source: $cms
MD
cat > src/Umbraco.Community.PriceBadge/Umbraco.Community.PriceBadge.csproj <<'XML'
<Project Sdk="Microsoft.NET.Sdk.Razor">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <Version>17.1.0</Version>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Umbraco.Cms.Web.Common" Version="[17.6.1, 18.0.0)" />
  </ItemGroup>
</Project>
XML
cat > src/Umbraco.Community.PriceBadge/Converters/PriceValueConverter.cs <<'CS'
using System.Globalization;
using Umbraco.Cms.Core.Models.PublishedContent;
using Umbraco.Cms.Core.PropertyEditors;

namespace Umbraco.Community.PriceBadge.Converters;

public sealed class PriceValueConverter : PropertyValueConverterBase
{
    public override bool IsConverter(IPublishedPropertyType propertyType)
        => propertyType.EditorAlias == "PriceBadge";

    public override Type GetPropertyValueType(IPublishedPropertyType propertyType) => typeof(decimal?);

    public override object? ConvertSourceToIntermediate(
        IPublishedElement owner,
        IPublishedPropertyType propertyType,
        object? source,
        bool preview)
        => decimal.TryParse(source?.ToString(), NumberStyles.Number, CultureInfo.InvariantCulture, out var price)
            ? price
            : null;
}
CS
