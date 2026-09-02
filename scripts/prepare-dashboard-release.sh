#!/usr/bin/env bash

set -euo pipefail

: "${APP_VERSION:?APP_VERSION is required}"
: "${SOURCE_SHA:?SOURCE_SHA is required}"

FORCE_UPDATE="${FORCE_UPDATE:-false}"
APP_NAME="${APP_NAME:-dashboard}"
CHANNEL="${CHANNEL:-release}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-artifacts}"
RELEASE_FILES_DIR="${RELEASE_FILES_DIR:-release-files}"
MANIFEST_PATH="${MANIFEST_PATH:-manifest.json}"

if [[ ! "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?(\+[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$ ]]; then
  echo "Unsupported semantic version: $APP_VERSION" >&2
  exit 1
fi

if [[ ! "$SOURCE_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  echo "SOURCE_SHA must be a full lowercase commit SHA" >&2
  exit 1
fi

if [[ "$FORCE_UPDATE" != "true" && "$FORCE_UPDATE" != "false" ]]; then
  echo "FORCE_UPDATE must be true or false" >&2
  exit 1
fi

if [[ "$APP_NAME" != "dashboard" && "$APP_NAME" != "dashboard-android" ]]; then
  echo "Unsupported app name: $APP_NAME" >&2
  exit 1
fi

if [[ "$CHANNEL" != "release" ]]; then
  echo "Only the release channel is supported" >&2
  exit 1
fi

VERSION_DIR="${APP_NAME}/${CHANNEL}/versions/v${APP_VERSION}"
mkdir -p "$RELEASE_FILES_DIR"

copy_single_artifact() {
  local artifact_dir="$1"
  local pattern="$2"
  local destination="$3"
  local match
  local matches=()

  while IFS= read -r -d '' match; do
    matches+=("$match")
  done < <(
      find "$ARTIFACTS_DIR/$artifact_dir" \
        -type f \
        -name "$pattern" \
        -print0
    )

  if [[ "${#matches[@]}" -ne 1 ]]; then
    echo "Expected exactly one $pattern in $artifact_dir, found ${#matches[@]}" >&2
    exit 1
  fi

  cp "${matches[0]}" "$RELEASE_FILES_DIR/$destination"
}

WINDOWS_NAME="dashboard-windows-x64-v${APP_VERSION}.exe"
MACOS_INTEL_NAME="dashboard-macos-intel-v${APP_VERSION}.dmg"
MACOS_ARM_NAME="dashboard-macos-apple-silicon-v${APP_VERSION}.dmg"
LINUX_DEB_NAME="dashboard-linux-x64-v${APP_VERSION}.deb"
LINUX_APPIMAGE_NAME="dashboard-linux-x64-v${APP_VERSION}.AppImage"

copy_single_artifact "dashboard-windows-x64" "*.exe" "$WINDOWS_NAME"
copy_single_artifact "dashboard-macos-intel" "*.dmg" "$MACOS_INTEL_NAME"
copy_single_artifact "dashboard-macos-apple-silicon" "*.dmg" "$MACOS_ARM_NAME"
copy_single_artifact "dashboard-linux-x64" "*.deb" "$LINUX_DEB_NAME"
copy_single_artifact "dashboard-linux-x64" "*.AppImage" "$LINUX_APPIMAGE_NAME"

artifact_json() {
  local file="$1"
  local object_key="${VERSION_DIR}/$(basename "$file")"
  local size

  if [[ "$(uname -s)" == "Darwin" ]]; then
    size="$(stat -f '%z' "$file")"
  else
    size="$(stat -c '%s' "$file")"
  fi

  jq -n \
    --arg filename "$(basename "$file")" \
    --arg object_key "$object_key" \
    --arg sha256 "$(sha256sum "$file" | awk '{print $1}')" \
    --argjson size "$size" \
    '{
      filename: $filename,
      object_key: $object_key,
      sha256: $sha256,
      size: $size
    }'
}

WINDOWS_JSON="$(artifact_json "$RELEASE_FILES_DIR/$WINDOWS_NAME")"
MACOS_INTEL_JSON="$(artifact_json "$RELEASE_FILES_DIR/$MACOS_INTEL_NAME")"
MACOS_ARM_JSON="$(artifact_json "$RELEASE_FILES_DIR/$MACOS_ARM_NAME")"
LINUX_DEB_JSON="$(artifact_json "$RELEASE_FILES_DIR/$LINUX_DEB_NAME")"
LINUX_APPIMAGE_JSON="$(artifact_json "$RELEASE_FILES_DIR/$LINUX_APPIMAGE_NAME")"

jq -n \
  --argjson schema_version 2 \
  --arg app "$APP_NAME" \
  --arg channel "$CHANNEL" \
  --arg version "$APP_VERSION" \
  --arg commit "$SOURCE_SHA" \
  --arg build_time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson force "$FORCE_UPDATE" \
  --argjson windows "$WINDOWS_JSON" \
  --argjson macos_intel "$MACOS_INTEL_JSON" \
  --argjson macos_arm "$MACOS_ARM_JSON" \
  --argjson linux_deb "$LINUX_DEB_JSON" \
  --argjson linux_appimage "$LINUX_APPIMAGE_JSON" \
  '{
    schema_version: $schema_version,
    app: $app,
    channel: $channel,
    version: $version,
    commit: $commit,
    build_time: $build_time,
    force: $force,
    artifacts: {
      windows: $windows,
      "macos-intel": $macos_intel,
      "macos-apple-silicon": $macos_arm,
      linux: $linux_deb,
      "linux-appimage": $linux_appimage
    }
  }' > "$MANIFEST_PATH"

jq empty "$MANIFEST_PATH"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "version=$APP_VERSION"
    echo "channel=$CHANNEL"
    echo "version_dir=$VERSION_DIR"
  } >> "$GITHUB_OUTPUT"
fi

echo "Prepared ${APP_NAME} v${APP_VERSION} release manifest for source $SOURCE_SHA"
