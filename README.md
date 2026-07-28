# Andless Dashboard Builds

This public repository contains only the packaging workflow for the private
[`andless-tech/dashboard`](https://github.com/andless-tech/dashboard)
repository. It does not mirror or publish the dashboard source code.

## Build a package

1. Open **Actions → Build private dashboard → Run workflow**.
2. Enter one of the accepted private source refs:
   - `main`
   - a full 40-character commit SHA
   - a version tag such as `v0.1.0`
3. Leave `release_tag` empty for 14-day Actions artifacts, or set a version tag
   to create a draft GitHub Release.

The workflow resolves the requested ref to an immutable commit before starting
the platform matrix. When `release_tag` is set, its version is written into the
temporary Tauri build configuration so installer filenames match the source
tag. Release assets include `BUILD-METADATA.json` and `SHA256SUMS`.

## Automatic tag builds

`Watch private dashboard tags` checks the private repository every five minutes.
When the latest `v`-prefixed semantic version tag has no corresponding build
run, it dispatches `Build private dashboard` with that tag as both `source_ref`
and `release_tag`.

Only the latest version tag is considered. A failed build is not automatically
retried because its workflow run still acts as the deduplication marker; rerun
that workflow manually after fixing the failure. A rerun may replace assets
only while the matching GitHub Release remains a draft; published releases are
never overwritten.

GitHub may delay scheduled workflows during periods of high load. Scheduled
workflows in public repositories can also be disabled after 60 days without
repository activity.

## Security boundary

- Private source access uses a short-lived token minted by a GitHub App and
  explicitly scoped by each workflow job to `andless-tech/dashboard` with
  `Contents: Read`.
- Secrets are not available to fork pull requests.
- The build workflow accepts only `main`, full commit SHAs, and version tags;
  the automatic watcher dispatches version tags only.
- Third-party Actions are pinned to full commit SHAs.
- This repository does not hold OSS, MQTT, webhook, or code-signing
  credentials.
- Build caches are intentionally disabled so private build intermediates are
  not uploaded.

Anyone who can change a workflow on `main` could attempt to expose private
source. Keep workflow write access restricted to trusted maintainers and retain
branch protection and CODEOWNERS review for `.github/workflows/`.

The current GitHub App installation is organization-wide by administrator
choice. Although normal jobs request a dashboard-only token, a malicious
workflow with access to the App private key could request a broader token.
Restricting the App installation to the dashboard repository remains the safer
configuration.

The protected `private-source` environment must contain:

- `DASHBOARD_APP_ID`
- `DASHBOARD_APP_PRIVATE_KEY`

Do not replace these with a personal access token. The GitHub App must have no
organization or repository permissions other than read-only repository
contents.

## Current limitation

The generated packages use the signing configuration from the private source
repository. Public distribution should not begin until macOS notarization,
Windows Authenticode signing, and application/firmware update signature
verification are configured.
