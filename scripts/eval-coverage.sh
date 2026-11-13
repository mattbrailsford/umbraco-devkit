#!/usr/bin/env bash
# Builds docs/EVAL-COVERAGE.md: what to do next for each skill, which skills and which of their
# sections have evals, and the latest recorded scores (docs/eval-scores.json, written by
# scripts/record-eval-scores.sh).
#
# A knowledge case names the sections it tests in a comment line in its prompt.md frontmatter
# (a comment, because `claude plugin eval` rejects frontmatter keys it doesn't know):
#   # covers: ["Section heading"]
# using a `## ` heading from the skill's SKILL.md or references/*.md. `[]` marks a guard for a
# removed rule. Workflow cases (tagged `workflow`) and should-not-trigger cases don't need one.
#
# Usage: scripts/eval-coverage.sh          rewrite docs/EVAL-COVERAGE.md
#        scripts/eval-coverage.sh --check  exit 1 if it's out of date or a covers value is wrong

set -euo pipefail
# Sort byte by byte, as CI does. A UTF-8 locale ignores hyphens when sorting, so the report
# would come out in a different order on a developer's machine and fail --check in CI.
export LC_ALL=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

skills_dir="plugins/umbraco-devkit/skills"
evals_dir="plugins/umbraco-devkit/evals"
scores="docs/eval-scores.json"
out="docs/EVAL-COVERAGE.md"

# Gain = with-plugin score minus without-plugin score, in points (0–100).
clear_gain=20     # at least this: the skill clearly helps
no_gain=10        # below this: no real help
under_covered=50  # below this % of sections with an eval: under-covered
stale_days=90     # a recorded score older than this should be rerun

# A context section (background, scope, sources, a review list restating other sections) has
# nothing an eval could fail, so its heading is written in italics: `## *Two server setups*`.
# It doesn't count toward coverage.
context_heading='^[*_].*[*_]$'

# One line per recorded case: name, with, without, skill loaded, runs, date. Read once.
scores_tsv=""
if [[ -f "$scores" ]]; then
  scores_tsv="$(jq -r 'to_entries[] | [.key, (.value.with // "–"), (.value.without // "–"),
    (.value.skillLoaded // "–"), (.value.runs // "–"), (.value.date // "–")] | @tsv' "$scores")"
fi

# One line per case and covered section: case name, section.
covers_tsv="$(for p in "$evals_dir"/*/prompt.md; do
  n="$(basename "$(dirname "$p")")"
  sed -n 's/^# covers:[[:space:]]*//p' "$p" | jq -r --arg n "$n" '.[] | [$n, .] | @tsv' 2>/dev/null || true
done)"

# One line per case and tag: case name, tag.
tags_tsv="$(for p in "$evals_dir"/*/prompt.md; do
  n="$(basename "$(dirname "$p")")"
  sed -n 's/^tags:[[:space:]]*\[\(.*\)\].*/\1/p' "$p" | tr ',' '\n' | tr -d ' ' | sed "s/^/$n\t/"
done)"

tags_of() { awk -F'\t' -v c="$1" '$1 == c { print $2 }' <<<"$tags_tsv"; }
covers_of() { awk -F'\t' -v c="$1" '$1 == c { print $2 }' <<<"$covers_tsv"; }
# `## ` lines inside code fences (example issue bodies, templates) aren't sections.
all_headings_of() {
  cat "$skills_dir/$1/SKILL.md" "$skills_dir/$1"/references/*.md 2>/dev/null |
    awk '/^[[:space:]]*(```|~~~)/ { fence = !fence; next } !fence && /^## / { sub(/^## /, ""); print }'
}
headings_of() { all_headings_of "$1" | grep -Ev "$context_heading" || true; }
context_count() { all_headings_of "$1" | grep -cE "$context_heading" || true; }
# field <case> <column>: 2 with, 3 without, 4 skill loaded, 5 runs, 6 date; "–" if not recorded.
field() {
  local v
  v="$(awk -F'\t' -v c="$1" -v n="$2" '$1 == c { print $n; exit }' <<<"$scores_tsv")"
  echo "${v:-–}"
}
is_num() { [[ "$1" =~ ^-?[0-9]+$ ]]; }
loaded_cell() {
  local l r; l="$(field "$1" 4)"; r="$(field "$1" 5)"
  if is_num "$l" && is_num "$r"; then echo "$l/$r"; else echo "–"; fi
}
link() { echo "[\`$1\`](#$1)"; }

errors=0
summary="$(mktemp)"
body="$(mktemp)"
tmp="$(mktemp)"
trap 'rm -f "$summary" "$body" "$tmp"' EXIT

# Actions, one bullet per line, filled in per skill below.
act_remove=""; act_trigger=""; act_prove=""; act_cover=""; act_unrun=""; act_workflow=""; act_stale=""
# Stale = recorded more than $stale_days days before the newest recorded score. Measured from the
# newest score, not today, so the report only changes when scores do and CI stays stable.
newest="$(awk -F'\t' '$6 != "–" { print $6 }' <<<"$scores_tsv" | sort | tail -1)"
stale_before=""
if [[ -n "$newest" ]]; then
  stale_before="$(date -u -d "$newest -$stale_days days" +%F 2>/dev/null ||
    date -u -j -v-"$stale_days"d -f %F "$newest" +%F)"
fi
nl=$'\n'

for skill_file in "$skills_dir"/*/SKILL.md; do
  skill="$(basename "$(dirname "$skill_file")")"

  cases=(); quiet=(); real=0; workflow=false
  for name in $(awk -F'\t' -v s="$skill" '$2 == s { print $1 }' <<<"$tags_tsv" | sort -u); do
    tags="$(tags_of "$name")"
    if grep -qxF should-not-trigger <<<"$tags"; then quiet+=("$name"); continue; fi
    cases+=("$name")
    grep -qxF workflow <<<"$tags" && workflow=true
    grep -qxF real-bug <<<"$tags" && real=$((real + 1))
  done

  printf '\n### `%s`\n\n' "$skill" >> "$body"

  if $workflow; then
    # Workflow cases test the skill keeps its own rules: anything under 100 broke one.
    kind="workflow"; covered="–"; best="–"; status="Keeps its rules"
    unrun=(); broke=()
    echo "| Eval | Score | Recorded |" >> "$body"
    echo "|---|---|---|" >> "$body"
    for c in ${cases[@]+"${cases[@]}"}; do
      w="$(field "$c" 2)"
      echo "| \`$c\` | $w | $(field "$c" 6) |" >> "$body"
      if ! is_num "$w"; then unrun+=("$c"); elif [[ "$w" -lt 100 ]]; then broke+=("\`$c\` ($w)"); fi
    done
    if [[ ${#broke[@]} -gt 0 ]]; then
      status="Broke a rule"
      act_workflow+="- $(link "$skill"): ${broke[*]}. Read the run, then fix the skill or the grader.$nl"
    fi
    if [[ ${#unrun[@]} -gt 0 ]]; then
      [[ "$status" == "Keeps its rules" ]] && status="Not run"
      act_unrun+="- $(link "$skill"): $(printf '`%s` ' "${unrun[@]}" | sed 's/ $//')$nl"
    fi
  else
    kind="knowledge"
    headings="$(headings_of "$skill")"
    total=0; hit=0
    echo "| Section | Eval | With | Without | Gain | Skill loaded | Recorded |" >> "$body"
    echo "|---|---|---|---|---|---|---|" >> "$body"
    while IFS= read -r h; do
      [[ -n "$h" ]] || continue
      total=$((total + 1)); found=false
      for c in ${cases[@]+"${cases[@]}"}; do
        if covers_of "$c" | grep -qxF "$h"; then
          found=true
          w="$(field "$c" 2)"; wo="$(field "$c" 3)"; g="–"
          is_num "$w" && is_num "$wo" && g="$((w - wo))"
          echo "| $h | \`$c\` | $w | $wo | $g | $(loaded_cell "$c") | $(field "$c" 6) |" >> "$body"
        fi
      done
      if $found; then hit=$((hit + 1)); else echo "| $h | **no eval** | | | | | |" >> "$body"; fi
    done <<<"$headings"
    covered="$hit/$total"

    # Gain across the cases that test a section (guards for removed rules don't count).
    # best: highest gain on any eval. proven: highest gain where the skill loaded in at least
    # half the runs, so the gain can be credited to the skill.
    best=""; best_case=""; proven=""; scored=0; unrun=(); unmapped=(); rarely=()
    for c in ${cases[@]+"${cases[@]}"}; do
      cv="$(covers_of "$c")"
      if [[ -z "$cv" ]]; then unmapped+=("$c"); continue; fi
      while IFS= read -r v; do
        if ! grep -qxF "$v" <<<"$headings"; then
          echo "# covers: \"$v\" in $evals_dir/$c/prompt.md is not a section of $skill" >&2
          errors=1
        fi
      done <<<"$cv"
      w="$(field "$c" 2)"; wo="$(field "$c" 3)"
      if ! is_num "$w" && ! is_num "$wo"; then unrun+=("$c"); continue; fi
      is_num "$w" && is_num "$wo" || continue
      scored=$((scored + 1))
      g=$((w - wo))
      if [[ -z "$best" || "$g" -gt "$best" ]]; then best="$g"; best_case="$c"; fi
      l="$(field "$c" 4)"; r="$(field "$c" 5)"
      if is_num "$l" && is_num "$r" && [[ $((l * 2)) -lt "$r" ]]; then
        # A clear gain the skill mostly didn't load for: the gain may come from elsewhere.
        if [[ "$g" -ge "$clear_gain" ]]; then
          rarely+=("\`$c\` (+$g, loaded $l/$r)")
        fi
      elif [[ -z "$proven" || "$g" -gt "$proven" ]]; then
        proven="$g"
      fi
    done
    if [[ ${#rarely[@]} -gt 0 ]]; then
      act_trigger+="- $(link "$skill"): ${rarely[*]}. Fix its description's \"Use when\" for these requests, then rerun to see if the gain holds.$nl"
    fi

    if [[ "$scored" -eq 0 ]]; then
      status="Unproven"; best="–"
      act_prove+="- $(link "$skill"): no eval has both a with and a without score. Run its evals with the default ablation.$nl"
    elif [[ -n "$proven" && "$proven" -ge "$clear_gain" ]]; then
      status="Proven"; best="$proven"
    elif [[ "$best" -ge "$clear_gain" ]]; then
      status="Gain, skill rarely loads"
    elif [[ "$best" -lt "$no_gain" ]]; then
      status="No gain"
      act_remove+="- $(link "$skill"): best gain $best over $scored scored eval(s). Run the removal check (\"Removing a rule\" in \`write-skill-eval\`) on its sections.$nl"
    else
      status="Small gain"
      act_prove+="- $(link "$skill"): best gain only $best (\`$best_case\`). Rerun with \`--runs 6\`, or add a harder scenario.$nl"
    fi
    if [[ "$best" != "–" && "$best" -gt 0 ]]; then best="+$best"; fi

    if [[ "$total" -gt 0 && $((hit * 100 / total)) -lt "$under_covered" ]]; then
      act_cover+="$((total - hit))	- $(link "$skill"): $((total - hit)) of $total sections have no eval.$nl"
    fi
    if [[ ${#unrun[@]} -gt 0 ]]; then
      act_unrun+="- $(link "$skill"): $(printf '`%s` ' "${unrun[@]}" | sed 's/ $//')$nl"
    fi
    if [[ ${#unmapped[@]} -gt 0 ]]; then
      {
        echo
        echo "No section: $(printf '`%s` ' "${unmapped[@]}" | sed 's/ $//')"
        echo
        echo "These test something with no rule in the skill: a guard for a rule plain Claude was"
        echo "shown to follow (kept so a regression shows up), or a case not yet mapped."
      } >> "$body"
    fi
  fi

  if [[ ${#quiet[@]} -gt 0 ]]; then
    printf '\nStays quiet on: %s\n' "$(printf '`%s` ' "${quiet[@]}" | sed 's/ $//')" >> "$body"
  fi

  ctx="–"; $workflow || ctx="$(context_count "$skill")"
  stale=()
  for c in ${cases[@]+"${cases[@]}"}; do
    d="$(field "$c" 6)"
    if [[ -n "$stale_before" && "$d" != "–" && "$d" < "$stale_before" ]]; then stale+=("$c"); fi
  done
  if [[ ${#stale[@]} -gt 0 ]]; then
    act_stale+="- $(link "$skill"): $(printf '`%s` ' "${stale[@]}" | sed 's/ $//')$nl"
  fi

  echo "| $(link "$skill") | $kind | $status | $best | ${#cases[@]} | $real | $covered | $ctx |" >> "$summary"
done

# Under-covered skills, most untested sections first.
act_cover="$(sed '/^$/d' <<<"$act_cover" | sort -t$'\t' -k1,1rn | cut -f2-)"

section() {
  # section <title> <why> <bullets>
  local bullets; bullets="$(sed '/^$/d' <<<"$3")"
  [[ -n "$bullets" ]] || return 0
  printf '### %s\n\n%s\n\n%s\n\n' "$1" "$2" "$bullets"
}

{
  echo "# Eval coverage"
  echo
  echo "Generated by \`scripts/eval-coverage.sh\` from the eval cases in \`$evals_dir/\` and the"
  echo "scores in \`docs/eval-scores.json\`. Don't edit it by hand."
  echo
  echo "## What to do next"
  echo
  section "Consider removing" \
    "Plain Claude already does what these skills teach: gain under $no_gain points on every scored eval." \
    "$act_remove"
  section "Fix when the skill loads" \
    "These evals gain, but the skill mostly didn't load, so the gain may come from elsewhere." \
    "$act_trigger"
  section "Prove the gain" \
    "No baseline yet, or the gain is too small to trust." \
    "$act_prove"
  section "Under-covered" \
    "Fewer than $under_covered% of the skill's sections have an eval, so most of its rules are unproven." \
    "$act_cover"
  section "Workflow rules broken" \
    "A workflow eval scored under 100, so the skill broke one of its own rules." \
    "$act_workflow"
  section "Stale scores" \
    "Recorded more than $stale_days days before the newest score. Rerun them, then \`scripts/record-eval-scores.sh\`." \
    "$act_stale"
  section "Evals never run" \
    "No recorded score. Run them, then \`scripts/record-eval-scores.sh\`." \
    "$act_unrun"
  echo "## Summary"
  echo
  echo "| Skill | Kind | Status | Best gain | Evals | Real bugs | Sections covered | Context |"
  echo "|---|---|---|---|---|---|---|---|"
  cat "$summary"
  echo
  echo "## How to read this"
  echo
  echo "- **Gain:** with-plugin score minus without-plugin score, from the latest recorded run"
  echo "  (0–100 each). **Best gain** is the skill's highest, counting only evals where the skill"
  echo "  loaded when it's proven. Guards for removed rules don't count."
  echo "- **Status, knowledge skills:** **Proven** = an eval gains $clear_gain or more and the skill loaded"
  echo "  in at least half its runs. **Gain, skill rarely loads** = the gain is there but the skill"
  echo "  mostly didn't load, so it may come from elsewhere."
  echo "  **Small gain** = $no_gain to $((clear_gain - 1)). **No gain** = under $no_gain. **Unproven** = no eval"
  echo "  with both scores."
  echo "- **Status, workflow skills:** they have no plain-Claude equivalent, so their evals check the"
  echo "  skill keeps its own rules. Anything under 100 broke one."
  echo "- **Sections covered:** the skill's \`## \` sections that at least one eval names in its"
  echo "  \`# covers:\` line. A section with no eval is a rule nobody has proven is needed."
  echo "- **Context:** sections with an italic heading (\`## *Background*\`): background, scope,"
  echo "  sources or a review list. They hold nothing an eval could fail, so they don't count."
  echo "- **Skill loaded:** in how many recorded with-plugin runs the skill actually loaded."
  echo "- **–** means nothing has been recorded."
  echo
  echo "## Skills in detail"
  cat "$body"
} > "$tmp"

if [[ "${1:-}" == "--check" ]]; then
  if ! diff -q "$tmp" "$out" > /dev/null 2>&1; then
    echo "$out is out of date. Run scripts/eval-coverage.sh and commit the result." >&2
    diff -u "$out" "$tmp" | head -40 >&2 || true
    errors=1
  fi
  [[ "$errors" -eq 0 ]] && echo "Eval coverage report is up to date."
  exit "$errors"
fi

cp "$tmp" "$out"
echo "Wrote $out"
exit "$errors"
