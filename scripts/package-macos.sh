#!/usr/bin/env bash
# Build a universal (arm64 + x86_64) Grok Desktop.app and wrap it in a DMG + zip.
# Intended to run on GitHub Actions (macos-15). Safe to run locally with full Xcode.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' GrokDesktop/Info.plist)"
DERIVED="${ROOT}/.ci/derived"
DIST="${ROOT}/dist"
STAGE="${ROOT}/.ci/dmg"
UNIVERSAL="${ROOT}/.ci/universal"
APP_NAME="Grok Desktop"
BIN_NAME="Grok Desktop"

mkdir -p "$DERIVED" "$DIST" "$UNIVERSAL"
rm -rf "$STAGE" "$UNIVERSAL"
mkdir -p "$STAGE" "$UNIVERSAL"

build_slice() {
  local arch="$1"
  echo "==> Building Release (${arch})"
  xcodebuild \
    -project GrokDesktop.xcodeproj \
    -scheme GrokDesktop \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "${DERIVED}/${arch}" \
    ARCHS="${arch}" \
    ONLY_ACTIVE_ARCH=YES \
    EXCLUDED_ARCHS= \
    ENABLE_PREVIEWS=NO \
    CODE_SIGN_IDENTITY='-' \
    CODE_SIGNING_ALLOWED=YES \
    build
}

build_slice arm64
build_slice x86_64

APP_ARM64="${DERIVED}/arm64/Build/Products/Release/${APP_NAME}.app"
APP_X86="${DERIVED}/x86_64/Build/Products/Release/${APP_NAME}.app"
APP="${UNIVERSAL}/${APP_NAME}.app"

if [[ ! -d "$APP_ARM64" ]]; then
  echo "error: missing arm64 app at $APP_ARM64" >&2
  exit 1
fi
if [[ ! -d "$APP_X86" ]]; then
  echo "error: missing x86_64 app at $APP_X86" >&2
  exit 1
fi

echo "==> Creating universal app"
cp -R "$APP_ARM64" "$APP"
lipo -create \
  "${APP_ARM64}/Contents/MacOS/${BIN_NAME}" \
  "${APP_X86}/Contents/MacOS/${BIN_NAME}" \
  -output "${APP}/Contents/MacOS/${BIN_NAME}"

# lipo invalidates the ad-hoc signature from each slice.
codesign --force --deep --sign - "$APP"

ARCHS="$(lipo -archs "${APP}/Contents/MacOS/${BIN_NAME}")"
echo "==> Architectures: ${ARCHS}"
echo "${ARCHS}" | grep -q 'arm64' || { echo "error: arm64 missing from universal binary" >&2; exit 1; }
echo "${ARCHS}" | grep -q 'x86_64' || { echo "error: x86_64 missing from universal binary" >&2; exit 1; }
file "${APP}/Contents/MacOS/${BIN_NAME}"
codesign --verify --deep --strict "$APP"

STEM="Grok-Desktop-${VERSION}-universal"
cp -R "$APP" "${STAGE}/"
ln -s /Applications "${STAGE}/Applications"

DMG="${DIST}/${STEM}.dmg"
ZIP="${DIST}/${STEM}.zip"
rm -f "$DMG" "$ZIP"

echo "==> Creating DMG"
hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG"

echo "==> Creating zip of ${APP_NAME}.app"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Artifacts"
ls -lh "$DMG" "$ZIP"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "VERSION=${VERSION}"
    echo "STEM=${STEM}"
    echo "DMG_NAME=${STEM}.dmg"
    echo "ZIP_NAME=${STEM}.zip"
    echo "DMG_PATH=${DMG}"
    echo "ZIP_PATH=${ZIP}"
  } >> "$GITHUB_OUTPUT"
fi
