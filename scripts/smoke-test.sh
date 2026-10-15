#!/usr/bin/env bash
# Compiles the non-UI sources with Tests/Smoke/main.swift and runs the checks.
set -euo pipefail
cd "$(dirname "$0")/.."

SDK="$(xcrun --show-sdk-path --sdk macosx)"
OUT="build/smoke-tests"
mkdir -p build

SOURCES=()
while IFS= read -r f; do SOURCES+=("$f"); done < <(find Sources/ClipVault -name '*.swift' ! -name 'ClipVaultApp.swift' | sort)

swiftc \
  -module-name ClipVaultSmoke \
  -target "$(uname -m)-apple-macos13.0" \
  -sdk "$SDK" \
  -framework AppKit -framework SwiftUI -framework ServiceManagement \
  "${SOURCES[@]}" Tests/Smoke/main.swift \
  -o "$OUT"

"$OUT"
