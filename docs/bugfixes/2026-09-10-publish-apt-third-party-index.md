# Ubuntu-Only Release Dependencies

## Symptom and Evidence

Dashboard v0.0.38 built successfully for all four targets and all installers,
the versioned manifest and latest manifest were uploaded to OSS. Both attempts
of run 34382005857 then failed before sending the MQTT announcement: global
`apt-get update` returned exit 100 for a Chrome repository `Hash Sum mismatch`.
The Ubuntu mosquitto package and the release artifacts were not the failure.

An automatic tag-watcher build, run 34382010905, raced the manual dispatch by
three seconds. It was cancelled to release the concurrency group for recovery
and to avoid rebuilding/replacing the same version's verified installers.

## Fix and Boundaries

Scope APT update and install to the runner's official Ubuntu source file, using
deb822 `ubuntu.sources` or the legacy main `sources.list` fallback. Disable only
extra source-list discovery for these invocations; do not edit runner sources,
ignore update failures, weaken signatures/hash checks, or mark a source trusted.
Use the same options for Linux build dependencies and both MQTT publication paths.
If the official source file is missing, fail explicitly rather than install from
unrelated repositories. Restore v0.0.38 using `publish_existing=true`; keep the
application tag, source commit and installer bytes unchanged.

This changes Ubuntu CI dependency installation only. The Windows and macOS
application code, binary compilation steps and versioned artifact scheme do not
change. The failed historical runs remain evidence of the original failure.

## Verification

- Workflow YAML parsed and all three changed bash steps passed `bash -n`.
- Read-only APT index inspection on Ubuntu 22.04 selected only the Ubuntu
  archive, excluding the machine's extra CUDA/cuDNN sources. No local packages
  or system repository files were changed.
- Recovery run 34385288505 on the fixed workflow succeeded. It validated the
  existing v0.0.38 manifest against source commit
  `0a5ac1a5809c23883dc76449611eed41e52ec450`, published latest, and acknowledged
  the retained QoS 1 MQTT announcement. No installers were rebuilt.
- The public update API and four platform download links already return 0.0.38;
  the complete Windows download matches its SHA-256 and embedded file version.

Reference: https://manpages.ubuntu.com/manpages/noble/man5/sources.list.5.html
