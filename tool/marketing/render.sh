#!/usr/bin/env bash
# Renders the marketing material from the app: the Arabic demo video and the
# images of the Facebook Page.
#
# Usage: [DHAMET_SERVER=https://…] tool/marketing/render.sh [compose_video.py options]
#
# Films the app (test/marketing/demo_video_test.dart), then writes
# marketing/video/ (tool/marketing/compose_video.py) and marketing/visuels/
# (tool/marketing/facebook_visuals.py). Set DHAMET_SERVER as for the release
# build: the home screen then shows online play. Options such as
# --audio voix.m4a or --silent go to compose_video.py. Requires ffmpeg,
# python3 with numpy, fontTools and Pillow (with libraqm), and the Noto Sans
# Arabic font (fonts-noto-core).
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"

python3 tool/store/make_screenshot_fonts.py
flutter test test/marketing \
  --dart-define=DEMO_VIDEO=true \
  ${DHAMET_SERVER:+--dart-define=DHAMET_SERVER="$DHAMET_SERVER"}
python3 tool/marketing/compose_video.py "$@"
python3 tool/marketing/facebook_visuals.py
