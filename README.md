# hub-sync

Keeps the **orchestral-hub** organisation's StackStorm packs in sync with
[StackStorm Exchange](https://github.com/StackStorm-Exchange), using only GitHub Actions.

| Workflow | When | What it does | Steps |
|---|---|---|---|
| **Quarterly sync** (`quarterly-sync.yml`) | 1 Jan/Apr/Jul/Oct, or by hand | Copies new packs to the hub as public repos (after checking them). Updates packs we haven't changed. Opens a "Sync with upstream" PR for packs we have changed, so our work is never overwritten. | 1, 2, 3, 8, 9 |
| **Recreate upstream PR** (`recreate-upstream-pr.yml`) | By hand | Copies an upstream PR into the hub repo as branch `upstream-pr/<N>` and opens the same PR there. | 4 → 6 |
| **Pack report** (`report.yml`) | Mondays, or by hand | Checks every hub pack, shows which are behind upstream, lists open hub PRs with test results and open upstream PRs (new ones marked). Saves `reports/latest.md` and opens an issue if anything fails. | 2, 4, 5, 6 |

Testing PRs (step 5) is mostly done by the packs themselves: almost every pack ships StackStorm's
CI workflow, which runs lint and unit tests on each PR. Merging (step 7) is done on GitHub once
those checks pass.

## How updates work

| Hub repo compared with upstream | What the Quarterly sync does |
|---|---|
| Doesn't exist yet | Checks the pack; if it passes, creates the public repo and pushes the code and tags |
| Same as upstream, or only has our own extra commits | Nothing |
| Behind upstream, no changes of ours | Fast-forwards it, if the new version passes the check |
| Behind upstream and has our changes, the new version fails the check, or branch protection blocks the push | Opens or refreshes a PR from branch `hub-sync/upstream` |

Commits someone adds to `hub-sync/upstream` (for example to fix conflicts) are never overwritten.

Skipped automatically: repos with no `pack.yaml` (`ci`, `web`, `index`, ...), archived repos
(unless *include archived* is ticked), empty repos, and anything listed in `config/exclude.txt`.

## Setup

### 1. Create this repo
Create `orchestral-hub/hub-sync` on GitHub **empty**: no README, `.gitignore` template **None**,
license **None** (this repo already contains them). Then push:

```bash
git init -b main && git add . && git commit -m "Add hub-sync"
git remote add origin https://github.com/orchestral-hub/hub-sync.git
git push -u origin main
```

### 2. Give the workflows access to the organisation
A workflow's built-in token can only change its own repo, so hub-sync needs its own credentials.

**Option A (recommended): a GitHub App.** Organisation settings → Developer settings → GitHub Apps → New.
- Webhook: off.
- Repository permissions:
  - Administration: Read and write (to create repos)
  - Contents: Read and write
  - Pull requests: Read and write
  - Workflows: Read and write (the packs contain `.github/workflows` files)
  - Checks: Read-only
  - Commit statuses: Read-only
- Install it on the organisation with **All repositories**.
- In hub-sync → Settings → Secrets and variables → Actions:
  - variable `HUB_APP_ID` = the App ID
  - secret `HUB_APP_PRIVATE_KEY` = the private key (`.pem` contents)

**Option B: a personal access token**, saved as secret `HUB_TOKEN`.
- Fine-grained: resource owner `orchestral-hub`, All repositories, the same permissions as above.
- Classic: scopes `repo` and `workflow`.

Optional variables: `HUB_ORG` (default `orchestral-hub`), `UPSTREAM_ORG` (default `StackStorm-Exchange`).

### 3. Organisation settings
- **Actions → General → Policies:** allow actions and reusable workflows from `StackStorm-Exchange/*`.
  The packs' CI uses `StackStorm-Exchange/ci/.github/workflows/...@master`.
- **Member privileges:** make sure public repositories can be created.
- hub-sync's **Pack report** commits to `main`. If you protect `main`, let GitHub Actions push to it.

### 4. First run
1. Actions → **Quarterly sync** → Run workflow with *dry run* ticked. The run's summary page lists
   what would be created.
2. Run it again without dry run and *only* = `stackstorm-email stackstorm-jira` to try two packs.
3. Run it without dry run and with *only* empty to copy everything. Later runs happen on the schedule.
4. Run **Pack report** once to get the first `reports/latest.md`.

## Day to day
- Read `reports/latest.md` or the latest **Pack report** run. New upstream PRs are marked *new*.
- To bring an upstream PR over: Actions → **Recreate upstream PR** → repo (e.g. `stackstorm-aws`) and PR number.
- Review and merge hub PRs on GitHub once their checks pass. That includes the quarterly
  "Sync with upstream" PRs.

## Things to know
- Hub repos are standalone copies, not forks: no "forked from" label and Actions run normally.
- On every push to `master`, most packs run a *Release* workflow that tags the version in
  `pack.yaml`. That's harmless on the hub; disable it per repo if you don't want the tags.
- GitHub App tokens last one hour; a full sync of ~180 packs takes well under that.
- GitHub pauses scheduled workflows after 60 days without commits. The weekly report commit
  prevents that.

## Running locally
Needs `bash`, `git`, `jq`, `gh` (logged in with `gh auth login`) and optionally PyYAML.

```bash
DRY_RUN=true ONLY="stackstorm-aws" WORK_DIR=./work scripts/quarterly_sync.sh
```

## Files
| Path | Purpose |
|---|---|
| `scripts/lib.sh` | Shared settings, GitHub helpers and the pack check |
| `scripts/quarterly_sync.sh` | Quarterly sync |
| `scripts/recreate_upstream_pr.sh` | Recreate an upstream PR on the hub |
| `scripts/report.sh` | Pack report |
| `config/exclude.txt` | Upstream repos never to copy |
| `reports/` | Latest report (`latest.md`, `*.tsv`), committed by the Pack report |
| `state/upstream_prs.json` | Upstream PRs seen in the last report, used to mark new ones |
| `.github/actions/setup` | Shared setup: PyYAML, token, git credentials |
