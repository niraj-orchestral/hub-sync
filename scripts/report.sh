#!/usr/bin/env bash
# Steps 2, 4, 5 and 6: report on all hub packs and open PRs.
#
#   * verifies every hub pack (default branch) and shows how it compares with upstream
#   * lists open PRs on hub packs with their CI result and verifies each PR's code
#   * lists open upstream PRs, marking ones that are new since the last report and
#     ones already recreated on the hub
#
# Writes reports/latest.md, reports/*.tsv and state/upstream_prs.json.
# Sets the step output "failures" (packs or hub PRs that fail) when run in Actions.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

REPORT_DIR="${REPORT_DIR:-$REPO_ROOT/reports}"
STATE_DIR="${STATE_DIR:-$REPO_ROOT/state}"
mkdir -p "$REPORT_DIR" "$STATE_DIR" "$WORK_DIR/report"

PACKS_TSV="$REPORT_DIR/packs.tsv"
HUB_PRS_TSV="$REPORT_DIR/hub_prs.tsv"
UP_PRS_TSV="$REPORT_DIR/upstream_prs.tsv"
STATE_PRS="$STATE_DIR/upstream_prs.json"

# CI result of a PR from its status checks.
CI_JQ='[.statusCheckRollup[]? | (.conclusion // .state // "")] as $c
  | if ($c | length) == 0 then "no checks"
    elif any($c[]; IN("FAILURE","ERROR","TIMED_OUT","CANCELLED","ACTION_REQUIRED","STARTUP_FAILURE")) then "failing"
    elif any($c[]; IN("","PENDING","EXPECTED","QUEUED","IN_PROGRESS")) then "running"
    else "passing" end'

# ---------------------------------------------------------------------------
# Packs
# ---------------------------------------------------------------------------
log "Listing repositories ..."
declare -A UP_BRANCH=()
while IFS=$'\t' read -r name branch _ _; do UP_BRANCH[$name]="$branch"; done < <(list_upstream_repos)
mapfile -t HUB_ROWS < <(list_hub_repos)

declare -A HUB_PACK=()
commits() { (( $1 == 1 )) && echo "1 commit" || echo "$1 commits"; }
printf 'pack\tstatus\tref\tversion\tissues\tupstream\n' > "$PACKS_TSV"
for row in "${HUB_ROWS[@]}"; do
  IFS=$'\t' read -r name hub_branch <<<"$row"
  [[ -n "${UP_BRANCH[$name]:-}" ]] || continue      # only repos that come from upstream
  HUB_PACK[$name]=1
  wanted "$name" || continue
  dir="$WORK_DIR/report/$name"
  rm -rf "$dir"
  if ! git clone --quiet "$(hub_url "$name")" "$dir" 2>/dev/null || ! git -C "$dir" rev-parse -q --verify HEAD >/dev/null; then
    printf '%s\tFAIL\t-\t-\tcould not clone hub repo (empty?)\t-\n' "$name" >> "$PACKS_TSV"; continue
  fi
  ub="${UP_BRANCH[$name]}"
  hub_sha="$(git -C "$dir" rev-parse HEAD)"
  if git_anon -C "$dir" fetch --quiet "$(upstream_url "$name")" "refs/heads/$ub:refs/upstream/$ub" 2>/dev/null; then
    up_sha="$(git -C "$dir" rev-parse "refs/upstream/$ub")"
    behind="$(git -C "$dir" rev-list --count "$hub_sha..$up_sha")"
    ahead="$(git -C "$dir" rev-list --count "$up_sha..$hub_sha")"
    if   (( behind == 0 && ahead == 0 )); then upstream="up to date"
    elif (( behind == 0 ));               then upstream="own changes ($(commits "$ahead"))"
    elif (( ahead == 0 ));                then upstream="behind upstream ($(commits "$behind"))"
    else upstream="own changes ($(commits "$ahead")) + behind upstream ($(commits "$behind"))"; fi
  else
    upstream="upstream not reachable"
  fi
  printf '%s\t%s\n' "$(verify_pack "$name" "$dir")" "$upstream" >> "$PACKS_TSV"
done
log "Verified $(( $(wc -l < "$PACKS_TSV") - 1 )) packs."

# ---------------------------------------------------------------------------
# Open PRs on the hub
# ---------------------------------------------------------------------------
log "Checking open PRs on $HUB_ORG ..."
gh search prs --owner "$HUB_ORG" --state open --limit 1000 \
  --json repository,number,title,url > "$WORK_DIR/hub_prs.json"

printf 'pr\tci\tstatus\tissues\ttitle\turl\n' > "$HUB_PRS_TSV"
while IFS=$'\t' read -r name num title url; do
  [[ -n "${UP_BRANCH[$name]:-}" ]] || continue
  wanted "$name" || continue
  dir="$WORK_DIR/report/$name"
  ci="$(gh pr view "$num" -R "$HUB_ORG/$name" --json statusCheckRollup --jq "$CI_JQ" </dev/null 2>/dev/null || echo unknown)"
  v="$name#$num"$'\t'"FAIL"$'\t-\t-\t'"could not fetch PR code"
  if [[ -d "$dir/.git" ]] && git -C "$dir" fetch --quiet origin "refs/pull/$num/head:refs/pr/$num" 2>/dev/null; then
    wt="$WORK_DIR/report/$name-pr-$num"
    rm -rf "$wt"
    git -C "$dir" worktree add --quiet --detach "$wt" "refs/pr/$num"
    v="$(verify_pack "$name#$num" "$wt")"
    git -C "$dir" worktree remove --force "$wt"
  fi
  IFS=$'\t' read -r _ vstatus _ _ vissues <<<"$v"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name#$num" "$ci" "$vstatus" "$vissues" "$title" "$url" >> "$HUB_PRS_TSV"
done < <(jq -r '.[] | [.repository.name, .number, .title, .url] | @tsv' "$WORK_DIR/hub_prs.json" | sort -V)

# ---------------------------------------------------------------------------
# Open PRs upstream
# ---------------------------------------------------------------------------
log "Checking open PRs on $UPSTREAM_ORG ..."
gh search prs --owner "$UPSTREAM_ORG" --state open --limit 1000 \
  --json repository,number,title,url,author,updatedAt > "$WORK_DIR/up_prs.json"
[[ -f "$STATE_PRS" ]] || echo '[]' > "$STATE_PRS"

# Upstream PRs already recreated on the hub: titles "[upstream #N] ...".
recreated="$(jq -r '.[] | select(.title | test("^\\[upstream #[0-9]+\\]")) |
                 "\(.repository.name)#\(.title | capture("^\\[upstream #(?<n>[0-9]+)\\]").n)"' "$WORK_DIR/hub_prs.json")"

printf 'pr\tnew\ton_hub\tauthor\tupdated\ttitle\turl\n' > "$UP_PRS_TSV"
jq -r --slurpfile prev "$STATE_PRS" '.[] | "\(.repository.name)#\(.number)" as $k |
        [$k, (if ($prev[0] | index($k)) then "-" else "new" end),
         .author.login, (.updatedAt[0:10]), .title, .url] | @tsv' "$WORK_DIR/up_prs.json" | sort -V |
while IFS=$'\t' read -r key new author updated title url; do
  [[ -n "${HUB_PACK[${key%%#*}]:-}" ]] || continue   # only packs that are on the hub
  wanted "${key%%#*}" || continue
  on_hub="no"; grep -qxF "$key" <<<"$recreated" && on_hub="yes"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$key" "$new" "$on_hub" "$author" "$updated" "$title" "$url"
done >> "$UP_PRS_TSV"

# Remember which upstream PRs we've seen (only on full runs).
[[ -n "$ONLY" ]] || jq '[.[] | "\(.repository.name)#\(.number)"] | sort' "$WORK_DIR/up_prs.json" > "$STATE_PRS"

# ---------------------------------------------------------------------------
# Markdown report
# ---------------------------------------------------------------------------
# awk helper: escape a markdown table cell
AWK_MD='function md(x) { gsub(/\|/, "\\|", x); return x } '
count() { tail -n +2 "$1" | cut -f"$2" | grep -c -x -- "$3" || true; }
packs_total=$(( $(wc -l < "$PACKS_TSV") - 1 ))
hub_prs_total=$(( $(wc -l < "$HUB_PRS_TSV") - 1 ))
up_prs_total=$(( $(wc -l < "$UP_PRS_TSV") - 1 ))
pack_fail=$(count "$PACKS_TSV" 2 FAIL)
pr_fail=$(tail -n +2 "$HUB_PRS_TSV" | awk -F'\t' '$2=="failing" || $3=="FAIL"' | wc -l)
up_new=$(count "$UP_PRS_TSV" 2 new)
up_on_hub=$(count "$UP_PRS_TSV" 3 yes)

{
  echo "# Pack report $(date -u +%F)"
  echo
  echo "$UPSTREAM_ORG → $HUB_ORG"
  echo
  echo "| | |"
  echo "|---|---|"
  echo "| Packs on the hub | $packs_total: $(count "$PACKS_TSV" 2 OK) OK, $(count "$PACKS_TSV" 2 WARN) WARN, $pack_fail FAIL |"
  echo "| Up to date with upstream | $(count "$PACKS_TSV" 6 "up to date") |"
  echo "| Open PRs on the hub | $hub_prs_total ($pr_fail failing) |"
  echo "| Open PRs upstream | $up_prs_total ($up_new new since last report, $up_on_hub recreated on the hub) |"
  echo

  echo "## Packs that need attention"
  echo
  rows="$(tail -n +2 "$PACKS_TSV" | awk -F'\t' "$AWK_MD"'$2!="OK" || $6!="up to date" { print "| " $1 " | " $2 " | " $4 " | " $6 " | " md($5) " |" }')"
  if [[ -n "$rows" ]]; then
    echo "| Pack | Check | Version | Upstream | Issues |"
    echo "|---|---|---|---|---|"
    echo "$rows"
  else
    echo "None: every pack passes and is up to date."
  fi
  echo

  echo "## Open PRs on $HUB_ORG"
  echo
  if (( hub_prs_total )); then
    echo "| PR | Tests (CI) | Pack check | Title |"
    echo "|---|---|---|---|"
    tail -n +2 "$HUB_PRS_TSV" | awk -F'\t' "$AWK_MD"'{ print "| [" $1 "](" $6 ") | " $2 " | " $3 " " md($4) " | " md($5) " |" }'
  else
    echo "None."
  fi
  echo

  echo "## New upstream PRs since the last report"
  echo
  rows="$(tail -n +2 "$UP_PRS_TSV" | awk -F'\t' "$AWK_MD"'$2=="new" { print "| [" $1 "](" $7 ") | `" $4 "` | " $5 " | " $3 " | " md($6) " |" }')"
  if [[ -n "$rows" ]]; then
    echo "| PR | Author | Updated | On hub | Title |"
    echo "|---|---|---|---|---|"
    echo "$rows"
  else
    echo "None."
  fi
  echo
  echo "All $up_prs_total open upstream PRs are listed in \`reports/upstream_prs.tsv\`."
  echo "To bring one over, run the **Recreate upstream PR** workflow with the repo name and PR number."
} > "$REPORT_DIR/latest.md"

summary < "$REPORT_DIR/latest.md"

failures=$(( pack_fail + pr_fail ))
log "Report written to $REPORT_DIR/latest.md ($failures failures)."
[[ -z "${GITHUB_OUTPUT:-}" ]] || echo "failures=$failures" >> "$GITHUB_OUTPUT"
