#!/usr/bin/env bash
# Steps 4 -> 6: recreate an upstream StackStorm Exchange PR on the matching hub repo.
#
#   recreate_upstream_pr.sh <repo> <pr-number>
#
# Pushes the upstream PR's code to the hub repo as branch "upstream-pr/<number>" and
# opens a PR from it into the hub repo's default branch. Running it again for the
# same PR refreshes the branch and comments on the existing hub PR.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

name="${1:?usage: $0 <repo> <pr-number>}"
num="${2:?usage: $0 <repo> <pr-number>}"
valid_repo_name "$name" || die "invalid repo name: $name"
[[ "$num" =~ ^[0-9]+$ ]] || die "invalid PR number: $num"

pr_json="$WORK_DIR/upstream-pr-$name-$num.json"
gh api "repos/$UPSTREAM_ORG/$name/pulls/$num" > "$pr_json" \
  || die "PR #$num not found in $UPSTREAM_ORG/$name"
field() { jq -r "$1" "$pr_json"; }
title="$(field .title)"; author="$(field .user.login)"; url="$(field .html_url)"
state="$(field .state)"; merged="$(field .merged)"; commits="$(field .commits)"
[[ "$state" == open ]] || log "WARNING: upstream PR is $state (merged: $merged); recreating it anyway."

hub_branch="$(hub_default_branch "$name")"
[[ -n "$hub_branch" ]] || die "$HUB_ORG/$name does not exist yet. Run the Quarterly sync first."

dir="$WORK_DIR/pr/$name-$num"
rm -rf "$dir"
git clone --quiet --no-checkout "$(hub_url "$name")" "$dir"
git_anon -C "$dir" fetch --quiet "$(upstream_url "$name")" "refs/pull/$num/head:refs/upstream-pr/$num" \
  || die "could not fetch upstream PR #$num"
pr_sha="$(git -C "$dir" rev-parse "refs/upstream-pr/$num")"
git -C "$dir" checkout --quiet --detach "$pr_sha"

verify="$(verify_pack "$name#$num" "$dir")"
vstatus="$(cut -f2 <<<"$verify")"; vissues="$(cut -f5 <<<"$verify")"

# Commits on the PR branch the hub doesn't have. More than the PR's own commits means
# the PR is based on upstream changes the hub hasn't synced yet.
extra=$(( $(git -C "$dir" rev-list --count "origin/$hub_branch..$pr_sha") - commits ))
note=""
if (( extra > 0 )); then
  note="> **Note:** this PR is based on a newer upstream version, so it also brings in $extra upstream commit(s) that $HUB_ORG/$name doesn't have yet. Consider running the Quarterly sync (or merging its sync PR) first."
fi

branch="upstream-pr/$num"
git -C "$dir" push --quiet --force origin "$pr_sha:refs/heads/$branch"

# The original description goes in a code block so its @mentions and #references
# don't notify people or link to the wrong issues.
body="$WORK_DIR/pr-body-$name-$num.md"
{
  echo "Recreated from upstream PR $url (author: \`$author\`, upstream state: $state)."
  echo
  echo "Upstream head: \`${pr_sha:0:7}\` · Pack verification: **$vstatus** ${vissues}"
  echo
  [[ -z "$note" ]] || { echo "$note"; echo; }
  echo "<details><summary>Original description</summary>"
  echo
  echo '````text'
  field '.body // "(no description)"'
  echo '````'
  echo
  echo "</details>"
  echo
  echo "_Opened by hub-sync._"
} > "$body"

existing="$(gh pr list -R "$HUB_ORG/$name" --head "$branch" --state open --json url --jq '.[0].url // empty')"
if [[ -n "$existing" ]]; then
  gh pr comment "$existing" --body "Branch \`$branch\` refreshed to upstream head \`${pr_sha:0:7}\`. Pack verification: **$vstatus** ${vissues}" >/dev/null
  hub_pr="$existing"; action="updated"
else
  hub_pr="$(gh pr create -R "$HUB_ORG/$name" --base "$hub_branch" --head "$branch" \
              --title "[upstream #$num] $title" --body-file "$body")"
  action="created"
fi
log "Hub PR $action: $hub_pr"

summary <<EOF
## Upstream PR recreated

| | |
|---|---|
| Upstream PR | $url |
| Hub PR ($action) | $hub_pr |
| Branch | \`$branch\` at \`${pr_sha:0:7}\` |
| Pack verification | **$vstatus** $(md_cell "$vissues") |

$note

The pack's own CI runs on the hub PR. Merge it on GitHub once the checks pass.
EOF
