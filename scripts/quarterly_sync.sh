#!/usr/bin/env bash
# Steps 1-3, 8 and 9: copy StackStorm Exchange packs into the hub organisation and keep them up to date.
#
# For every upstream repo:
#   * not a pack (no pack.yaml), archived, empty or in config/exclude.txt -> skipped
#   * not on the hub yet        -> verified; if it passes, a public hub repo is created and pushed
#   * on the hub, unchanged     -> nothing to do
#   * hub has no own changes    -> fast-forwarded to upstream (if the new version passes verification)
#   * hub has its own changes,
#     verification fails, or a
#     direct push is refused    -> a "Sync with upstream" PR is opened/updated on the hub repo,
#                                  so nothing merged on the hub is ever overwritten
#
# Settings: see lib.sh, plus
#   DRY_RUN=true            report what would happen, change nothing
#   INCLUDE_ARCHIVED=true   also copy archived upstream repos
#   SYNC_BRANCH             hub branch used for sync PRs (default: hub-sync/upstream)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DRY_RUN="${DRY_RUN:-false}"
INCLUDE_ARCHIVED="${INCLUDE_ARCHIVED:-false}"
SYNC_BRANCH="${SYNC_BRANCH:-hub-sync/upstream}"
RESULTS="$WORK_DIR/sync-results.tsv"
CHANGED="$WORK_DIR/changed-packs.txt"
CREATE_LIMITED="$WORK_DIR/create-limit-reached"
: > "$RESULTS"
rm -f "$CREATE_LIMITED"

record() {   # record <repo> <result> [details]
  printf '%s\t%s\t%s\n' "$1" "$2" "${3:-}" >> "$RESULTS"
  log "$1: $2${3:+ ($3)}"
}

# Push to a hub repo. On failure sets PUSH_ERR to a short reason; for GitHub push
# protection (secrets in the upstream history) it starts with "secret-scanning:" and
# carries the links that allow those secrets.
PUSH_ERR=""
hub_push() {   # hub_push <dir> <git push args...>
  local dir="$1" out links; shift
  if out="$(git -C "$dir" push --quiet "$@" 2>&1)"; then PUSH_ERR=""; return 0; fi
  if grep -q -e 'GH013' -e 'Push cannot contain secrets' <<<"$out"; then
    links="$(grep -o 'https://github.com/[^ ]*/unblock-secret/[^ ]*' <<<"$out" | sort -u | tr '\n' ' ')"
    PUSH_ERR="secret-scanning: ${links% }"
  else
    PUSH_ERR="$(grep -v '^remote: *$' <<<"$out" | tail -3 | tr '\n' ' ')"
  fi
  return 1
}

push_failed() {   # push_failed <repo> <what>
  if [[ "$PUSH_ERR" == secret-scanning:* ]]; then
    record "$1" BLOCKED "GitHub push protection found secrets in the upstream history. Open each link, choose a reason to allow it, then re-run with only = $1. Links: ${PUSH_ERR#secret-scanning: }"
  else
    record "$1" FAILED "$2 failed: $PUSH_ERR"
  fi
}

# Open (or refresh) the "Sync with upstream" PR on a hub repo.
open_sync_pr() {
  local name="$1" dir="$2" hub_branch="$3" up_branch="$4" up_sha="$5" hub_sha="$6" reason="$7" verify="$8"
  local hub; hub="$(hub_url "$name")"

  if [[ "$DRY_RUN" == true ]]; then
    record "$name" "would open sync PR" "$reason"; return 0
  fi

  # Don't clobber commits someone added to the sync branch (e.g. conflict fixes).
  local cur
  cur="$(git -C "$dir" ls-remote "$hub" "refs/heads/$SYNC_BRANCH" | cut -f1)"
  if [[ -n "$cur" && "$cur" != "$up_sha" ]]; then
    git -C "$dir" fetch --quiet "$hub" "refs/heads/$SYNC_BRANCH:refs/hub-sync-branch"
    if ! git -C "$dir" merge-base --is-ancestor "$cur" "$up_sha"; then
      record "$name" "sync PR left as is" "$SYNC_BRANCH has manual commits; upstream is now ${up_sha:0:7}"
      return 0
    fi
  fi
  hub_push "$dir" --force "$hub" "$up_sha:refs/heads/$SYNC_BRANCH" || { push_failed "$name" "push of $SYNC_BRANCH"; return 0; }

  local base body num url
  base="$(git -C "$dir" merge-base "$hub_sha" "$up_sha" || echo "$hub_sha")"
  body="$WORK_DIR/pr-body-$name.md"
  cat > "$body" <<EOF
## Upstream update from $UPSTREAM_ORG/$name

Upstream \`$up_branch\` is now at [\`${up_sha:0:7}\`]($(upstream_web "$name")/commit/$up_sha).
Upstream changes since our last sync: $(upstream_web "$name")/compare/${base:0:12}...${up_sha:0:12}

**Why this needs review:** $reason

**Pack verification of the upstream version:** \`$(cut -f2 <<<"$verify")\` $(cut -f5 <<<"$verify")

If GitHub reports conflicts, resolve them on the \`$SYNC_BRANCH\` branch (GitHub's
"Resolve conflicts" button, or merge \`$hub_branch\` into it locally and push).
The quarterly sync will not overwrite manual commits on that branch.

_Opened by hub-sync._
EOF
  num="$(gh pr list -R "$HUB_ORG/$name" --head "$SYNC_BRANCH" --state open --json number --jq '.[0].number // empty')"
  if [[ -n "$num" ]]; then
    gh pr comment "$num" -R "$HUB_ORG/$name" --body-file "$body" >/dev/null
    record "$name" "sync PR updated" "#$num: $reason"
  else
    url="$(gh pr create -R "$HUB_ORG/$name" --base "$hub_branch" --head "$SYNC_BRANCH" \
            --title "Sync with upstream $UPSTREAM_ORG/$name (${up_sha:0:7})" --body-file "$body")"
    record "$name" "sync PR opened" "$url: $reason"
  fi
}

sync_pack() {
  local name="$1" up_branch="$2"
  local dir="$WORK_DIR/sync/$name" hub up_sha hub_branch hub_sha verify vstatus vissues
  hub="$(hub_url "$name")"
  rm -rf "$dir"

  if ! git_anon clone --quiet --no-checkout "$(upstream_url "$name")" "$dir" 2>/dev/null; then
    record "$name" FAILED "clone from upstream failed"; return 0
  fi
  if ! up_sha="$(git -C "$dir" rev-parse --verify -q "refs/remotes/origin/$up_branch")"; then
    record "$name" skipped "upstream branch $up_branch is empty"; return 0
  fi
  git -C "$dir" checkout --quiet --detach "$up_sha"

  verify="$(verify_pack "$name" "$dir")"
  vstatus="$(cut -f2 <<<"$verify")"; vissues="$(cut -f5 <<<"$verify")"
  if [[ "$vstatus" == NOT_A_PACK ]]; then
    record "$name" skipped "not a pack (no pack.yaml)"; rm -rf "$dir"; return 0
  fi

  hub_branch="$(hub_default_branch "$name")"
  hub_sha=""
  if [[ -n "$hub_branch" ]] \
     && git -C "$dir" fetch --quiet "$hub" "refs/heads/$hub_branch:refs/hub/$hub_branch" 2>/dev/null; then
    hub_sha="$(git -C "$dir" rev-parse "refs/hub/$hub_branch")"
  fi

  # ---- New pack (or hub repo exists but is still empty) -------------------
  if [[ -z "$hub_sha" ]]; then
    if [[ "$vstatus" == FAIL ]]; then
      record "$name" "not uploaded" "verification failed: $vissues"; return 0
    fi
    if [[ "$DRY_RUN" == true ]]; then
      record "$name" "would create" "$vstatus ${up_sha:0:7}"; return 0
    fi
    if [[ -z "$hub_branch" ]]; then
      # GitHub limits how many repos can be created per hour. Once we hit it, postpone the
      # rest to the next run instead of failing them.
      if [[ -f "$CREATE_LIMITED" ]]; then
        record "$name" postponed "GitHub's repo-creation limit was reached; the next run creates it"; return 0
      fi
      local err
      if ! err="$(gh repo create "$HUB_ORG/$name" --public --disable-wiki \
             --description "StackStorm pack $name, synced from $UPSTREAM_ORG/$name" \
             --homepage "$(upstream_web "$name")" 2>&1 >/dev/null)"; then
        if grep -qi 'too many repositories' <<<"$err"; then
          touch "$CREATE_LIMITED"
          record "$name" postponed "GitHub's repo-creation limit was reached; the next run creates it"
        else
          record "$name" FAILED "gh repo create failed: $err"
        fi
        return 0
      fi
      sleep 2   # GitHub throttles bulk repo creation
    fi
    if ! hub_push "$dir" "$hub" "$up_sha:refs/heads/$up_branch"; then
      push_failed "$name" "push to new hub repo"; return 0
    fi
    git -C "$dir" push --quiet "$hub" --tags 2>/dev/null || log "  $name: some tags were not pushed"
    gh api -X PATCH "repos/$HUB_ORG/$name" -f default_branch="$up_branch" >/dev/null || true
    record "$name" created "$vstatus ${up_sha:0:7}"
    echo "$name" >> "$CHANGED"
    return 0
  fi

  # ---- Existing pack ------------------------------------------------------
  if git -C "$dir" merge-base --is-ancestor "$up_sha" "$hub_sha"; then
    if [[ "$up_sha" == "$hub_sha" ]]; then
      record "$name" unchanged
    else
      record "$name" unchanged "hub has its own changes on top of upstream"
    fi
    return 0
  fi

  echo "$name" >> "$CHANGED"
  if git -C "$dir" merge-base --is-ancestor "$hub_sha" "$up_sha"; then
    # Hub has no changes of its own: plain fast-forward.
    if [[ "$vstatus" == FAIL ]]; then
      open_sync_pr "$name" "$dir" "$hub_branch" "$up_branch" "$up_sha" "$hub_sha" \
        "the new upstream version fails verification" "$verify"
    elif [[ "$DRY_RUN" == true ]]; then
      record "$name" "would update" "${hub_sha:0:7}..${up_sha:0:7}"
    elif hub_push "$dir" "$hub" "$up_sha:refs/heads/$hub_branch"; then
      git -C "$dir" push --quiet "$hub" --tags 2>/dev/null || true
      record "$name" updated "${hub_sha:0:7}..${up_sha:0:7}"
    elif [[ "$PUSH_ERR" == secret-scanning:* ]]; then
      push_failed "$name" "update push"
    else
      open_sync_pr "$name" "$dir" "$hub_branch" "$up_branch" "$up_sha" "$hub_sha" \
        "direct push to $hub_branch was refused (branch protection?)" "$verify"
    fi
  else
    open_sync_pr "$name" "$dir" "$hub_branch" "$up_branch" "$up_sha" "$hub_sha" \
      "orchestral-hub has its own changes to this pack" "$verify"
  fi
  rm -rf "$dir"
}

# ---------------------------------------------------------------------------
log "Listing $UPSTREAM_ORG repositories ..."
mapfile -t ROWS < <(list_upstream_repos)
log "Found ${#ROWS[@]} repositories. Dry run: $DRY_RUN"
: > "$CHANGED"

for row in "${ROWS[@]}"; do
  IFS=$'\t' read -r name branch archived size <<<"$row"
  wanted "$name" || continue
  if is_excluded "$name"; then record "$name" skipped "in config/exclude.txt"; continue; fi
  if [[ "$archived" == true && "$INCLUDE_ARCHIVED" != true ]]; then record "$name" skipped "archived upstream"; continue; fi
  if [[ "$size" == 0 ]]; then record "$name" skipped "empty upstream repo"; continue; fi
  # Run each pack in a subshell so one failure can't stop the whole run.
  set +e
  ( set -e; sync_pack "$name" "$branch" )
  rc=$?
  set -e
  (( rc == 0 )) || record "$name" FAILED "unexpected error (exit $rc), see log"
done

# ---------------------------------------------------------------------------
title="Quarterly sync: $UPSTREAM_ORG → $HUB_ORG"
[[ "$DRY_RUN" == true ]] && title+=" (dry run, nothing changed)"
{
  echo "## $title"
  echo
  echo "| Result | Packs |"
  echo "|---|---|"
  cut -f2 "$RESULTS" | sort | uniq -c | sort -rn | while read -r n what; do echo "| $what | $n |"; done
  echo
  if grep -q $'\tBLOCKED\t' "$RESULTS"; then
    echo "### Action needed: blocked by GitHub push protection"
    echo
    echo "These packs have secrets (old keys or tokens) somewhere in their upstream history, so GitHub"
    echo "refused the push. They are already public upstream. For each link: open it, choose a reason"
    echo "(e.g. *It's used in tests*) and click **Allow me to push this secret**. Then re-run this workflow"
    echo "with dry run unticked and *only* = \`$(grep $'\tBLOCKED\t' "$RESULTS" | cut -f1 | tr '\n' ' ' | sed 's/ $//')\`."
    echo
    grep $'\tBLOCKED\t' "$RESULTS" | while IFS=$'\t' read -r n _ det; do
      echo "- **$n**"
      for link in ${det##*Links: }; do echo "  - $link"; done
    done
    echo
  fi
  if grep -q $'\tpostponed\t' "$RESULTS"; then
    echo "> **$(grep -c $'\tpostponed\t' "$RESULTS") packs postponed:** GitHub limits how many repos can be created per hour."
    echo "> Re-run this workflow in about an hour (dry run unticked) to create them."
    echo
  fi
  if grep -qv -e $'\tunchanged' -e $'\tskipped' -e $'\tBLOCKED\t' -e $'\tpostponed\t' "$RESULTS"; then
    echo "### Changes"
    echo
    echo "| Pack | Result | Details |"
    echo "|---|---|---|"
    grep -v -e $'\tunchanged' -e $'\tskipped' -e $'\tBLOCKED\t' -e $'\tpostponed\t' "$RESULTS" | while IFS=$'\t' read -r n what det; do
      echo "| $n | $what | $(md_cell "$det") |"
    done
  else
    echo "No other new or updated packs."
  fi
} | summary

if grep -q -e $'\tFAILED\t' -e $'\tBLOCKED\t' "$RESULTS"; then
  log "Some packs failed or are blocked; see the run summary."
  exit 1
fi
