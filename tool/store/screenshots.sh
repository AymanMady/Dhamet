#!/usr/bin/env bash
# Renders the Google Play screenshots from the app.
#
# Usage: [DHAMET_SERVER=https://…] tool/store/screenshots.sh
#
# Writes deploiement/google-play/screenshots/<language>/*.jpg, 1080 x 1920. Set
# DHAMET_SERVER as for the release build: the home screen then shows online
# play. Requires python3 with fontTools and Pillow, and the Noto Sans Arabic
# font (fonts-noto-core).
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"

python3 tool/store/make_screenshot_fonts.py
rm -rf build/store_screenshots
flutter test test/store \
  --dart-define=STORE_SCREENSHOTS=true \
  ${DHAMET_SERVER:+--dart-define=DHAMET_SERVER="$DHAMET_SERVER"}

# Google Play wants JPEG or 24-bit PNG, without transparency.
python3 - <<'PY'
from pathlib import Path
from PIL import Image

source = Path("build/store_screenshots")
target = Path("deploiement/google-play/screenshots")
for old in target.glob("*/*"):
    old.unlink()
for png in sorted(source.glob("*/*.png")):
    out = target / png.parent.name / (png.stem + ".jpg")
    out.parent.mkdir(parents=True, exist_ok=True)
    Image.open(png).convert("RGB").save(out, "JPEG", quality=92, optimize=True)
    print("wrote", out)
PY
