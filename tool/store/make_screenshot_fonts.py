"""Builds the fonts the store screenshots are rendered with.

Usage: python3 tool/store/make_screenshot_fonts.py

Tests have no system fonts, so no fallback for Arabic. This merges Roboto
(from the Flutter SDK) with Noto Sans Arabic (Debian/Ubuntu package
fonts-noto-core) into build/store_fonts/RobotoArabic-*.ttf, which
test/store/store_screenshots_test.dart loads as "Roboto": Arabic then looks
as it does on an Android phone. Requires fontTools.
"""

import shutil
import subprocess
import tempfile
from pathlib import Path

from fontTools.merge import Merger
from fontTools.ttLib import TTFont
from fontTools.ttLib.scaleUpem import scale_upem

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build/store_fonts"
NOTO = Path("/usr/share/fonts/truetype/noto")
WEIGHTS = ("Regular", "Medium", "Bold")


def flutter_root():
    flutter = shutil.which("flutter")
    if flutter is None:
        raise SystemExit("flutter is not on the PATH")
    return Path(subprocess.check_output(["readlink", "-f", flutter], text=True).strip()).parents[1]


def main():
    material = flutter_root() / "bin/cache/artifacts/material_fonts"
    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for weight in WEIGHTS:
            roboto = TTFont(material / f"Roboto-{weight}.ttf")
            arabic = TTFont(NOTO / f"NotoSansArabic-{weight}.ttf")
            scale_upem(arabic, roboto["head"].unitsPerEm)
            paths = [Path(tmp) / f"roboto-{weight}.ttf", Path(tmp) / f"arabic-{weight}.ttf"]
            roboto.save(paths[0])
            arabic.save(paths[1])
            out = OUT / f"RobotoArabic-{weight}.ttf"
            Merger().merge([str(p) for p in paths]).save(out)
            print("wrote", out.relative_to(ROOT))


if __name__ == "__main__":
    main()
