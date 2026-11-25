# hub-sync

Keeps the **orchestral-hub** organisation's StackStorm packs in sync with
[StackStorm Exchange](https://github.com/StackStorm-Exchange), using GitHub Actions.

## Quarterly sync

Runs automatically at 02:00 UTC on 1 Jan, 1 Apr, 1 Jul and 1 Oct. To run it by hand:
Actions → **Quarterly sync** → Run workflow.

| Input | Use |
|---|---|
| Dry run | Ticked: only reports what would change. Untick to make changes. Scheduled runs are always real. |
| Only these repos | Space-separated repo names, e.g. `stackstorm-aws stackstorm-jira`. Empty = all packs. |
| Also copy archived upstream repos | Leave unticked. Archived repos are retired packs. |

What it does:
- **New upstream packs** are checked and, if they pass, created as public repos in orchestral-hub.
- **Packs we haven't changed** are updated to the latest upstream version.
- **Packs we have changed** are never overwritten. Instead, a **"Sync with upstream"** PR is
  opened on that pack (branch `hub-sync/upstream`) for review. Merge it like any other PR.
  If it has conflicts, fix them on that branch; later syncs won't overwrite your fixes.
- Repos without a `pack.yaml` (`ci`, `web`, `index`, ...) and repos in `config/exclude.txt` are skipped.

The run's summary page lists every pack that was created, updated or got a sync PR.
A full run takes about 10–15 minutes.

## Pack report

Runs automatically every Monday at 06:00 UTC. To run it by hand:
Actions → **Pack report** → Run workflow (leave *only* empty for a full report).

It saves `reports/latest.md` in this repo and shows the same on the run's summary page:
- **Packs that need attention:** packs that fail the pack check or are behind upstream.
- **Open PRs on orchestral-hub:** each with its test (CI) result and pack check.
- **New upstream PRs since the last report:** with whether they've been recreated on the hub.
  All open upstream PRs are in `reports/upstream_prs.tsv`.

If any pack or hub PR fails, it opens (or comments on) an issue titled
**"Pack report: failures found"** in this repo.

The pack check looks at `pack.yaml` (name, description, version, author, `ref` format,
`python_versions`), the pack's folder layout and whether every YAML file is valid.

## Recreate upstream PR

Copies an open StackStorm Exchange PR into the matching orchestral-hub repo.
Actions → **Recreate upstream PR** → Run workflow, then enter:

| Input | Example |
|---|---|
| Pack repo name | `stackstorm-aws` |
| Upstream PR number | `113` |

It pushes the PR's code to branch `upstream-pr/<number>` and opens a PR titled
`[upstream #<number>] <original title>`. The pack's own CI tests it; merge it on GitHub
once the checks pass. Running it again for the same PR refreshes the branch.

If the hub repo is behind upstream, the PR may also bring in those upstream commits.
The PR description says so; merging the pack's sync PR first avoids it.

## Things to know

- **Token:** the workflows use the `HUB_TOKEN` secret. When it expires, generate a new one
  (scopes `repo` and `workflow`) and update the secret. Nothing else changes.
- **PR tests** rely on StackStorm's shared CI workflow, so orchestral-hub must allow actions
  from `StackStorm-Exchange/*` (Org settings → Actions).
- **Release tags:** most packs have a *Release* workflow that tags the `pack.yaml` version on
  each push to `master`. That's harmless; disable it in a pack if you don't want the tags.
- **Scheduled runs pause** if this repo has no commits for 60 days. The weekly report commit
  prevents that.
- **Excluding a pack:** add its repo name to `config/exclude.txt`.

## Running locally

Needs `bash`, `git`, `jq`, `gh` (logged in with `gh auth login`) and optionally PyYAML.

```bash
DRY_RUN=true ONLY="stackstorm-aws" WORK_DIR=./work scripts/quarterly_sync.sh
```
```bash
WORK_DIR=./work scripts/recreate_upstream_pr.sh stackstorm-aws 113
```
```bash
ONLY="stackstorm-aws" WORK_DIR=./work scripts/report.sh
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
| `.github/workflows/` | The three workflows |
| `.github/actions/setup` | Shared setup: PyYAML, token, git credentials |
