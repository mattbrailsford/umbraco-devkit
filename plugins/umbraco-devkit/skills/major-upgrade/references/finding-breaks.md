# Finding breaks: commands

Commands for inventory steps 2 and 5. `$CMS`, `$REMOTE` and the tags come from
`umbraco-cms-source`. Set `current_tag` to the project's current release and `target_tag`
to the target release.

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

## Which PR made a change

Find the commit that added or removed a line, then its PR:

```bash
git -C "$CMS" log -S'<signature as it was>' --no-merges --format='%h %s' \
  "${current_tag}..${target_tag}" -- <path>
gh api "repos/umbraco/Umbraco-CMS/commits/<sha>/pulls" -q '.[].number'
```

Umbraco's squash commits usually end with `(#12345)`, which names the PR without the API
call. Cherry-picks and merge-ups list the same change more than once: keep one entry per PR.

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
