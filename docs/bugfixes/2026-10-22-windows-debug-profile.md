# Windows Debug profile

Previously, Windows-only test builds still used the release compiler profile.
Not publishing a release did not make the executable a Debug build.

Add an optional build_mode input, defaulting to release for compatibility with
existing callers and scheduled tag builds. Debug requires Windows-only mode,
an empty release tag and publish_existing=false. Pass --debug to Tauri and
select the debug installer directory for renaming and artifact upload.

Only Windows Debug behavior is added; macOS/Linux and release publishing remain
unchanged. Verify the validation matrix, workflow syntax and an actual Windows
Actions build. Runtime diagnostics still require Windows hardware testing.
