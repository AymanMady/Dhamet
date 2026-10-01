#!/usr/bin/env bash
# Builds the Android App Bundle to upload to Google Play.
#
# Usage: DHAMET_SERVER=https://dhamet-server.onrender.com tool/release/build_release.sh
#
# DHAMET_SERVER is the multiplayer server of this build (HTTPS). Without
# it, the build has no online play. The Dart code is obfuscated; its
# symbols, needed to read crash stack traces, are kept in
# build/symbols/<version>/ (keep them for every published version).
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"

if [[ ! -f android/key.properties ]]; then
  echo "android/key.properties is missing: run tool/release/create_upload_key.sh" >&2
  echo "(Google Play refuses bundles signed with the debug key)." >&2
  exit 1
fi

server="${DHAMET_SERVER:-}"
if [[ -z "$server" ]]; then
  echo "DHAMET_SERVER is not set: this build has no online play." >&2
elif [[ "$server" != https://* ]]; then
  echo "DHAMET_SERVER must be an https:// address (release builds refuse plain HTTP)." >&2
  exit 1
fi

version="$(sed -n 's/^version: *//p' pubspec.yaml)"
symbols="build/symbols/$version"

flutter build appbundle --release \
  --obfuscate --split-debug-info="$symbols" \
  ${server:+--dart-define=DHAMET_SERVER="$server"}

echo
echo "Bundle:  build/app/outputs/bundle/release/app-release.aab"
echo "Symbols: $symbols"
