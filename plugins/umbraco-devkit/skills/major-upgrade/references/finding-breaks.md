# Finding breaks: commands

Commands for inventory steps 2 and 5, and for another Umbraco product's new major (Preflight
step 4). `$CMS`, `$REMOTE` and the tags come from `umbraco-cms-source`. Set `current_tag` to
the project's current release and `target_tag` to the target release.

They're written to run the same in bash and zsh, macOS and Linux:

- Write `"${tag}:path"` with braces. In zsh, `$tag:s` is read as a modifier.
- Loop with `while read -r`, never `for x in $var`: zsh doesn't split `$var` on spaces.
- Match whole words with `git grep -w`, not `\b`: macOS `git grep -E` has no `\b` and
  matches nothing without an error.
- Exclude `bin/` and `obj/` when grepping the project. `obj/project.assets.json` names every
  package and type and floods the results.

## Fetch only the tags you need

A full `fetch --tags` can fail on an unrelated stale branch ref. Fetch the two majors' tags
only:

```bash
git -C "$CMS" fetch --quiet "$REMOTE" \
  "refs/tags/release-<current major>.*:refs/tags/release-<current major>.*" \
  "refs/tags/release-<target major>.*:refs/tags/release-<target major>.*"
```

## Labelled PRs in the range

Start the search at the oldest commit in the range, not at the current major's `.0.0`
release. Work for the next major starts on its own branch long before the current major
ships.

```bash
since=$(git -C "$CMS" log --reverse --format=%cs "${current_tag}..${target_tag}" | head -1)

gh pr list -R umbraco/Umbraco-CMS --label category/breaking --state merged \
  --search "merged:>=${since}" --limit 1000 \
  --json number,title,baseRefName,mergeCommit \
  -q '.[] | "\(.number) \(.mergeCommit.oid) \(.baseRefName) \(.title)"' |
while read -r pr sha base title; do
  if git -C "$CMS" merge-base --is-ancestor "$sha" "$target_tag" 2>/dev/null; then
    git -C "$CMS" merge-base --is-ancestor "$sha" "$current_tag" 2>/dev/null ||
      echo "in       #$pr $title"
  elif [[ "$base" != v*/dev && "$base" != release/* && "$base" != main ]]; then
    echo "probably #$pr ($base) $title"
  fi
done
```

`in` lines are in the target and not the current release. `probably` lines were merged to a
feature branch that was later squash-merged, so their merge commit is in no tag. Check each
one by grepping the target tag for what it changed. If the limit is reached, split the
search by date.

## Open PRs still due in the release

Only when the target is a beta or RC. List the open PRs labelled for the major's final
release, with their `category/*` labels and changed files, then match the files against the
CMS types and subsystems the package uses:

```bash
gh pr list -R umbraco/Umbraco-CMS --state open --label "release/<major>.0.0" --limit 200 \
  --json number,title,labels,files \
  -q '.[] | "#\(.number) [\([.labels[].name | select(startswith("category/"))] | join(","))] \(.title)\n" + ([.files[].path | "    " + .] | join("\n"))'
```

## Which PR made a change

Find the commit that added or removed a line, then its PR:

```bash
git -C "$CMS" log -S'<signature as it was>' --no-merges --format='%h %s' \
  "${current_tag}..${target_tag}" -- <path>
gh api "repos/umbraco/Umbraco-CMS/commits/<sha>/pulls" -q '.[].number'
```

Umbraco's squash commits usually end with `(#12345)`, which names the PR without the API
call. Cherry-picks and merge-ups list the same change more than once: keep one entry per PR.

The same two commands name the PR in another Umbraco product's repo, when you can read it:
point `-C` at its clone and `repos/` at its repo.

## Another Umbraco product

For another product's new major (Deploy, Forms, Commerce). Many products have no labels and
no full release notes, and their source is often private. Start with what every package
developer can read, then add the source if you can read it.

1. **Public API of the two packages.** Restore the current and the target version of each
   product package the package references, from the feed Preflight found, and compare each
   assembly the package uses:

   ```bash
   dotnet nuget locals global-packages --list   # where restored packages live
   dotnet tool install --global Microsoft.DotNet.ApiCompat.Tool
   apicompat --left  <packages>/<id>/<current>/lib/<tfm>/<Assembly>.dll \
             --right <packages>/<id>/<target>/lib/<tfm>/<Assembly>.dll
   ```

   Each removed or changed member the package uses is an entry. This finds what no longer
   compiles or binds, not what changed behavior: each subsystem the package extends still
   gets its own scenario in the smoke, as inventory step 2 says.
2. **Docs and release notes.** Read the product's upgrade and version-specific pages, with
   `umbraco-docs`, and its release notes where they exist.
3. **The product's public issue tracker.** Umbraco's closed-source products keep one
   (`umbraco/Umbraco.Deploy.Issues`, `umbraco/Umbraco.Forms.Issues`,
   `umbraco/Umbraco.Commerce.Issues`). Search it for the target version and for the
   package's own name. Product teams often list the downstream packages a change needs. A
   hit is an entry:

   ```bash
   gh search issues --repo <owner>/<issues repo> "<Package.Name>"
   gh search issues --repo <owner>/<issues repo> "<target major>"
   ```

   Search for the NuGet id too, if it differs from the package name.
4. **The product's source, if you can read it.** Also do the following, in its repo:
   - List every PR merged between the current and target tags, with no label filter: run
     "Labelled PRs in the range" without `--label`. Read each description, not only the
     title.
   - Run the step 3 searches with `gh search prs` against the source repo.
   - Diff every type the package names, and the whole folder of each subsystem it extends,
     as inventory step 2 does for the CMS. For Deploy: service connectors, value
     connectors, entity type registration, and the backoffice entry points.
   - Name the PR behind each entry from `git log -S`, as "Which PR made a change" says,
     never from a PR title.
5. **Say how deep the search went.** In the upgrade file, list which of these sources were
   read and which weren't (source private, no release notes, the API compare still to run),
   so the reviewer knows what could still be missing.

## CMS types the package uses

List the `Umbraco.*` namespaces and the type names the package names, then find each type's
file at the current tag:

```bash
git -C "$CMS" grep -l -w -E '(class|interface|record|struct|enum) <TypeName>' \
  "${current_tag}" -- 'src/*.cs'
```

Diff each file across the range, following moves:

```bash
git -C "$CMS" diff -M "${current_tag}..${target_tag}" -- <path>
```

Every removed or changed `public` or `protected` line on a member the package uses is an
entry. For the backoffice, do the same with the `.ts` files that export the classes,
elements, contexts and types the package imports.

## Whole subsystem folders

```bash
git -C "$CMS" diff -M --stat "${current_tag}..${target_tag}" -- <folder>
git -C "$CMS" log --no-merges --format='%h %s' "${current_tag}..${target_tag}" -- <folder>
```

Read the `--stat` first: a folder that moved shows as renames, not as a delete and an add.

## CMS data migrations

```bash
git -C "$CMS" diff "${current_tag}..${target_tag}" -- \
  src/Umbraco.Infrastructure/Migrations/Upgrade/UmbracoPlan.cs
```

Each new `To<...>` line names a migration class. Read it at the target tag.

## Removals with no `[Obsolete]`

The CMS marks some removals only with a comment, often on a default interface member or an
overload:

```bash
git -C "$CMS" grep -n -E 'TODO:? \(?V<target major>\)?' "${current_tag}" -- 'src/*.cs'
```
