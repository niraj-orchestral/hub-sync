#!/usr/bin/env bash
# Shared helpers for the hub-sync scripts. Sourced by the other scripts, not run directly.
#
# Settings (environment variables):
#   UPSTREAM_ORG   source organisation           (default: StackStorm-Exchange)
#   HUB_ORG        our organisation              (default: orchestral-hub)
#   ONLY           space-separated repo names to limit a run to (default: all)
#   WORK_DIR       scratch space for clones      (default: $RUNNER_TEMP/hub-sync-work)
#   GIT_BASE_URL   git server                    (default: https://github.com; tests use a local dir)

UPSTREAM_ORG="${UPSTREAM_ORG:-StackStorm-Exchange}"
HUB_ORG="${HUB_ORG:-orchestral-hub}"
ONLY="${ONLY:-}"
GIT_BASE_URL="${GIT_BASE_URL:-https://github.com}"
WORK_DIR="${WORK_DIR:-${RUNNER_TEMP:-/tmp}/hub-sync-work}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXCLUDE_FILE="${EXCLUDE_FILE:-$REPO_ROOT/config/exclude.txt}"

export GIT_TERMINAL_PROMPT=0
mkdir -p "$WORK_DIR"

log() { printf '%s %s\n' "$(date -u '+%H:%M:%S')" "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

# Append markdown from stdin to the run's summary page (stdout when run locally).
summary() {
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then cat >> "$GITHUB_STEP_SUMMARY"; else cat; fi
}

# Escape text for a markdown table cell.
md_cell() { sed -e 's/|/\\|/g' <<<"$1" | tr -d '\n'; }

upstream_url() { printf '%s/%s/%s.git' "$GIT_BASE_URL" "$UPSTREAM_ORG" "$1"; }
hub_url()      { printf '%s/%s/%s.git' "$GIT_BASE_URL" "$HUB_ORG" "$1"; }
upstream_web() { printf 'https://github.com/%s/%s' "$UPSTREAM_ORG" "$1"; }

# Upstream repos are public: fetch them without sending our token.
git_anon() { git -c credential.helper= -c credential.https://github.com.helper= "$@"; }

# Upstream repos as: name <TAB> default_branch <TAB> archived <TAB> size
list_upstream_repos() {
  gh api --paginate "orgs/$UPSTREAM_ORG/repos?per_page=100&type=public" \
    --jq '.[] | [.name, .default_branch, .archived, .size] | @tsv' | sort
}

# Hub repos as: name <TAB> default_branch
list_hub_repos() {
  gh api --paginate "orgs/$HUB_ORG/repos?per_page=100" \
    --jq '.[] | [.name, .default_branch] | @tsv' | sort
}

# Default branch of a hub repo, or nothing if the repo does not exist.
# (On a 404, gh still prints the --jq result of the error body, i.e. "null", so check the exit code.)
hub_default_branch() {
  local b
  b="$(gh api "repos/$HUB_ORG/$1" --jq .default_branch 2>/dev/null)" || return 0
  [[ -n "$b" && "$b" != null ]] && printf '%s\n' "$b"
  return 0
}

# Is this repo selected by ONLY (empty ONLY = everything)?
wanted() { [[ -z "$ONLY" || " $ONLY " == *" $1 "* ]]; }

# Is this repo listed in config/exclude.txt?
is_excluded() {
  [[ -f "$EXCLUDE_FILE" ]] && sed -e 's/#.*//' -e 's/[[:space:]]//g' "$EXCLUDE_FILE" | grep -qxF "$1"
}

valid_repo_name() { [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]; }

# ---------------------------------------------------------------------------
# Pack verification
#   verify_pack <label> <dir>
#   prints: label <TAB> status <TAB> ref <TAB> version <TAB> issues
#   status: OK | WARN | FAIL | NOT_A_PACK
# ---------------------------------------------------------------------------
HAVE_PYYAML=0
python3 -c 'import yaml' 2>/dev/null && HAVE_PYYAML=1

_pack_field() {   # top-level "key: value" from pack.yaml (also "key : value", quoted values)
  { grep -E "^$1[[:space:]]*:" "$2" || true; } | head -1 \
    | sed -E "s/^$1[[:space:]]*:[[:space:]]*//; s/[[:space:]]+#.*$//; s/[[:space:]]+$//; s/^['\"]//; s/['\"]$//"
}

verify_pack() {
  local label="$1" d="$2" f="$2/pack.yaml"
  local status=OK ref version key bad joined="" errs=0 i
  local -a issues=()

  if [[ ! -f "$f" ]]; then
    printf '%s\tNOT_A_PACK\t-\t-\tno pack.yaml\n' "$label"; return 0
  fi

  ref="$(_pack_field ref "$f")"; [[ -n "$ref" ]] || ref="$(_pack_field name "$f")"
  version="$(_pack_field version "$f")"
  for key in name description version author; do
    [[ -n "$(_pack_field "$key" "$f")" ]] || issues+=("missing '$key'")
  done
  if [[ -n "$version" && ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+.].*)?$ ]]; then
    issues+=("version '$version' is not x.y.z")
  fi
  if [[ -n "$ref" && ! "$ref" =~ ^[a-z0-9_]+$ ]]; then
    issues+=("ref '$ref' must be lowercase letters, digits, _")
  fi
  grep -qE '^python_versions[[:space:]]*:' "$f" || issues+=("no python_versions (warn)")
  if [[ ! -d "$d/actions" && ! -d "$d/sensors" && ! -d "$d/rules" && ! -d "$d/aliases" && ! -d "$d/policies" ]]; then
    issues+=("no actions/sensors/rules/aliases/policies folder")
  fi

  if (( HAVE_PYYAML )); then
    bad="$(find "$d" -path "$d/.git" -prune -o \( -name '*.yaml' -o -name '*.yml' \) -type f -print0 \
      | xargs -0 -r python3 -I -c '
import sys, yaml
for p in sys.argv[1:]:
    try:
        with open(p) as fh:
            list(yaml.safe_load_all(fh))
    except Exception:
        print(p)' | sed "s#^$d/##" | tr '\n' ' ' | sed 's/ $//')"
    [[ -z "$bad" ]] || issues+=("invalid YAML: $bad")
  fi

  for i in "${issues[@]+"${issues[@]}"}"; do
    [[ "$i" == *"(warn)" ]] || errs=1
    joined+="${joined:+; }$i"
  done
  if (( errs )); then status=FAIL; elif (( ${#issues[@]} )); then status=WARN; fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$label" "$status" "${ref:--}" "${version:--}" "$joined"
}
