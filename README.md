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
4. Approve access to the protected `private-source` environment when prompted.

The workflow resolves the requested ref to an immutable commit before starting
the platform matrix. Release assets include `BUILD-METADATA.json` and
`SHA256SUMS`.

## Security boundary

- Private source access uses a read-only deploy key scoped only to
  `andless-tech/dashboard`.
- Secrets are not available to fork pull requests.
- The workflow is manual-only and accepts only `main`, full commit SHAs, and
  version tags.
- Third-party Actions are pinned to full commit SHAs.
- This repository does not hold OSS, MQTT, webhook, or code-signing
  credentials.
- Build caches are intentionally disabled so private build intermediates are
  not uploaded.

Anyone who can change a workflow and obtain approval for the
`private-source` environment could attempt to expose private source. Keep
workflow write access and environment approval restricted to trusted
maintainers.

## Current limitation

The generated packages use the signing configuration from the private source
repository. Public distribution should not begin until macOS notarization,
Windows Authenticode signing, and application/firmware update signature
verification are configured.
