#!/usr/bin/env bash
# Flags backtick-quoted, kebab-case tokens in this repo's Markdown that look like a skill
# reference (`some-skill`) but don't match any actual skill folder — the exact bug this repo
# hit repeatedly while renaming/splitting skills by hand. Not a perfect linter: a token that
# legitimately isn't a skill (a template name, an official Backoffice Skills plugin skill,
# an npm package) will get flagged once and needs adding to skill-ref-allowlist.txt.
#
# Usage: scripts/check-skill-refs.sh
# Exit code: 0 if every reference resolves, 1 if something needs a look.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

skills_dir="plugins/umbraco-devkit/skills"
allowlist_file="scripts/skill-ref-allowlist.txt"

# Valid names: every skill's own `name:` frontmatter value (the source of truth — not the
# folder name, in case they ever drift) plus the curated allowlist.
valid_names="$(mktemp)"
trap 'rm -f "$valid_names" "$found_tokens"' EXIT

for skill_file in "$skills_dir"/*/SKILL.md; do
  grep -m1 '^name:' "$skill_file" | sed 's/^name:[[:space:]]*//' >> "$valid_names"
done

if [[ -f "$allowlist_file" ]]; then
  sed 's/#.*$//' "$allowlist_file" | sed 's/[[:space:]]*$//' | grep -v '^[[:space:]]*$' >> "$valid_names"
fi

sort -u -o "$valid_names" "$valid_names"

# Every backtick-quoted, kebab-case (>= one hyphen) token across tracked Markdown files.
# docs/EVAL-COVERAGE.md is skipped: it's generated, and its backticked names are eval cases.
# plugins/umbraco-devkit/evals/ is skipped: a grader's or fixture's backticked tokens are
# routinely CSS properties, HTML/web-component tag names, or fictional fixture entities, not
# skill references — the stale-rename risk this check guards against lives in skill/agent
# prose and docs, not in eval judging criteria.
md_files() { git ls-files '*.md' ':!docs/EVAL-COVERAGE.md' ':!plugins/umbraco-devkit/evals/**'; }
found_tokens="$(mktemp)"
md_files \
  | xargs grep -ohE '`[a-z][a-z0-9]*(-[a-z0-9]+)+`' \
  | tr -d '`' \
  | sort -u > "$found_tokens"

unresolved=0
while IFS= read -r token; do
  if ! grep -qxF "$token" "$valid_names"; then
    unresolved=1
    echo "Unresolved reference: \`$token\`"
    md_files | xargs grep -n "\`$token\`" | sed 's/^/    /'
    echo
  fi
done < "$found_tokens"

if [[ "$unresolved" -eq 0 ]]; then
  echo "All skill references resolve."
  exit 0
else
  echo "Fix the reference (likely a stale rename), or add it to $allowlist_file if it's not" \
    "meant to be a skill in this plugin."
  exit 1
fi
