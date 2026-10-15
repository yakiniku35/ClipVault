#!/usr/bin/env bash
# Builds ClipVault.app without Xcode — only the Command Line Tools are needed.
#
#   scripts/build-app.sh            # universal (arm64 + x86_64) release build
#   ARCHS="x86_64" scripts/build-app.sh
#   CONFIG=debug scripts/build-app.sh
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-release}"
ARCHS="${ARCHS:-arm64 x86_64}"
MIN_OS="13.0"
OUT_DIR="build"
APP="$OUT_DIR/ClipVault.app"
SDK="$(xcrun --show-sdk-path --sdk macosx)"

if [[ "$CONFIG" == "release" ]]; then
  OPT_FLAGS=(-O -whole-module-optimization)
else
  OPT_FLAGS=(-Onone -g)
fi

SOURCES=()
while IFS= read -r f; do SOURCES+=("$f"); done < <(find Sources/ClipVault -name '*.swift' | sort)

mkdir -p "$OUT_DIR"
SLICES=()
for arch in $ARCHS; do
  echo "▸ Compiling ($arch, $CONFIG)…"
  mkdir -p "$OUT_DIR/$arch"
  swiftc \
    -parse-as-library \
    -module-name ClipVault \
    -target "${arch}-apple-macos${MIN_OS}" \
    -sdk "$SDK" \
    "${OPT_FLAGS[@]}" \
    -framework AppKit -framework SwiftUI -framework ServiceManagement \
    "${SOURCES[@]}" \
    -o "$OUT_DIR/$arch/ClipVault"
  SLICES+=("$OUT_DIR/$arch/ClipVault")
done

echo "▸ Assembling $APP…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
if (( ${#SLICES[@]} > 1 )); then
  lipo -create "${SLICES[@]}" -output "$APP/Contents/MacOS/ClipVault"
else
  cp "${SLICES[0]}" "$APP/Contents/MacOS/ClipVault"
fi
cp Resources/Info.plist "$APP/Contents/Info.plist"
if [[ -f Resources/AppIcon.icns ]]; then
  cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi
cp Resources/MenuBarIcon.png Resources/MenuBarIcon@2x.png "$APP/Contents/Resources/"
printf 'APPL????' > "$APP/Contents/PkgInfo"

echo "▸ Signing (ad-hoc)…"
codesign --force --sign - --timestamp=none "$APP"

echo "✓ Built $APP"
lipo -info "$APP/Contents/MacOS/ClipVault"
