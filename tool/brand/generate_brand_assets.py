"""Draws the Dhametna logo and writes every icon the stores need.

Usage: python3 tool/brand/generate_brand_assets.py

The logo is a patch of sand with a Dhamet board drawn in it by hand: the
alquerque cell (square, cross and diagonals). A Sultan stands in
the middle — two crossed sticks tied with an indigo cord, as the game
draws it — and a pebble waits at a corner. It is drawn by this script, not
cut from the reference art, so that it stays sharp at every size.

Writes:
- android/app/src/main/res/mipmap-*/   adaptive icon layers (background,
  foreground, monochrome for themed icons) and the legacy square and round
  icons for Android 7;
- android/app/src/main/res/drawable-*/splash_logo.png   the logo shown by
  the launch screen before Android 12;
- ios/Runner/Assets.xcassets/AppIcon.appiconset/   the iOS icons (opaque);
- assets/images/logo.png   the logo shown inside the app;
- deploiement/google-play/   the 512 x 512 Play icon and the 1024 x 500 feature
  graphic.

Requires numpy and Pillow (with libraqm, for the Arabic name).
"""

import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONT = ROOT / "assets/fonts/ReemKufi.ttf"

NAME_AR = "ظامتنا"
NAME_LATIN = "DHAMETNA"

# Colours, after lib/app/theme/app_colors.dart.
SAND_LIGHT = (240, 207, 146)
SAND_DEEP = (190, 128, 64)
GROOVE = (138, 92, 46)
GROOVE_RIM = (252, 232, 190)
WOOD_LIGHT = (240, 214, 164)
WOOD = (196, 146, 88)
WOOD_DARK = (110, 75, 42)
WOOD_CUT = (248, 230, 192)
INDIGO = (31, 58, 95)
INDIGO_LIGHT = (84, 118, 164)
STONE_LIGHT = (150, 140, 128)
STONE = (97, 89, 81)
STONE_DARK = (44, 38, 34)
SHADOW = (70, 40, 14)

# The adaptive icon layers are 108 dp; launchers show the central 72 dp
# (the "window"), and only the central 66 dp circle is never cut.
LAYER_DP = 108
WINDOW_DP = 72
MASTER = 2304  # master layer size in pixels (window: 1536 px)

DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


class Canvas:
    """Maps window coordinates (0..1, may overflow) to master pixels."""

    def __init__(self, size=MASTER):
        self.size = size
        self.offset = size * (LAYER_DP - WINDOW_DP) / 2 / LAYER_DP
        self.unit = size * WINDOW_DP / LAYER_DP

    def p(self, x, y):
        return (self.offset + x * self.unit, self.offset + y * self.unit)

    def d(self, length):
        return length * self.unit


# Board: a 3 x 3 alquerque cell, centred a little below the middle.
CENTER = (0.5, 0.52)
HALF = 0.28


def board_lines():
    """Square, cross and the diagonals through the centre: on the Dhamet
    board, diagonals only run through the "wide" points (docs/rules.md), so
    the midpoints of the sides have none."""
    cx, cy = CENTER
    left, right, top, bottom = cx - HALF, cx + HALF, cy - HALF, cy + HALF
    lines = []
    for x in (left, cx, right):
        lines.append(((x, top), (x, bottom)))
    for y in (top, cy, bottom):
        lines.append(((left, y), (right, y)))
    lines.append(((left, top), (right, bottom)))
    lines.append(((right, top), (left, bottom)))
    return lines


def overshoot(a, b, amount):
    """Extends a segment at both ends, as a finger-drawn line does."""
    (ax, ay), (bx, by) = a, b
    length = math.hypot(bx - ax, by - ay)
    ux, uy = (bx - ax) / length, (by - ay) / length
    return (ax - ux * amount, ay - uy * amount), (bx + ux * amount, by + uy * amount)


def blur(image, radius):
    return image.filter(ImageFilter.GaussianBlur(radius))


def shift(mask, dx, dy):
    return ImageChops.offset(mask, int(round(dx)), int(round(dy)))


def paint(base, colour, mask, opacity=1.0):
    """Paints [colour] on [base] (RGBA) through [mask] (L)."""
    if opacity != 1.0:
        mask = mask.point(lambda v: int(v * opacity))
    layer = Image.new("RGBA", base.size, colour + (255,))
    layer.putalpha(mask)
    base.alpha_composite(layer)


# --- Background: the sand and the drawn board ------------------------------


def sand(size, seed=7):
    """Warm sand, lighter in the middle, with a fine grain."""
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:size, 0:size].astype(np.float32) / size
    # Sun from the top left.
    distance = np.sqrt((x - 0.42) ** 2 + (y - 0.38) ** 2) / 0.8
    t = np.clip(distance, 0, 1) ** 1.4
    light, deep = np.array(SAND_LIGHT, np.float32), np.array(SAND_DEEP, np.float32)
    rgb = light * (1 - t[..., None]) + deep * t[..., None]
    grain = rng.normal(0, 1, (size, size)).astype(np.float32)
    grain = np.asarray(
        blur(Image.fromarray(((grain * 40) + 128).clip(0, 255).astype(np.uint8)), size / 900),
        np.float32,
    )
    rgb += ((grain - 128) / 128 * 7)[..., None]
    # Soft ripples left by the wind.
    ripples = np.sin((x * 0.8 + y * 1.6) * 34 + np.sin(x * 9) * 1.2)
    rgb += (ripples * 3)[..., None]
    return Image.fromarray(rgb.clip(0, 255).astype(np.uint8)).convert("RGBA")


def grooves(canvas, width):
    mask = Image.new("L", (canvas.size, canvas.size), 0)
    draw = ImageDraw.Draw(mask)
    w = canvas.d(width)
    for a, b in board_lines():
        a, b = overshoot(a, b, 0.022)
        draw.line([canvas.p(*a), canvas.p(*b)], fill=255, width=int(w))
        for end in (a, b):
            x, y = canvas.p(*end)
            draw.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=255)
    return mask


def draw_board(image, canvas):
    mask = blur(grooves(canvas, 0.03), canvas.d(0.003))
    d = canvas.d(0.007)
    # Lit from the top left: inside a groove, the wall nearest the sun is in
    # shadow and the far wall is lit; the sand pushed out on the far side
    # catches the light too.
    near_wall = ImageChops.subtract(mask, shift(mask, d, d))
    far_wall = ImageChops.subtract(mask, shift(mask, -d, -d))
    rim = ImageChops.subtract(shift(mask, d * 1.3, d * 1.3), mask)
    paint(image, GROOVE_RIM, blur(rim, canvas.d(0.004)), 0.7)
    paint(image, GROOVE, mask, 0.62)
    paint(image, SHADOW, blur(near_wall, canvas.d(0.003)), 0.6)
    paint(image, GROOVE_RIM, blur(far_wall, canvas.d(0.003)), 0.35)


def background(size=MASTER):
    canvas = Canvas(size)
    image = sand(size)
    draw_board(image, canvas)
    return image


# --- Foreground: the Sultan and the pebble ---------------------------------


def stick_polygon(canvas, base, top, base_width, top_width):
    (bx, by), (tx, ty) = canvas.p(*base), canvas.p(*top)
    length = math.hypot(tx - bx, ty - by)
    nx, ny = -(ty - by) / length, (tx - bx) / length
    bw, tw = canvas.d(base_width) / 2, canvas.d(top_width) / 2
    return [
        (bx + nx * bw, by + ny * bw),
        (tx + nx * tw, ty + ny * tw),
        (tx - nx * tw, ty - ny * tw),
        (bx - nx * bw, by - ny * bw),
    ]


def draw_stick(image, canvas, base, top, width=0.052):
    """A planted stick, lit from the left, with its cut end on top."""
    size = image.size
    polygon = stick_polygon(canvas, base, top, width, width * 0.8)
    body = Image.new("L", size, 0)
    ImageDraw.Draw(body).polygon(polygon, fill=255)
    # Rounded ends.
    draw = ImageDraw.Draw(body)
    for (x, y), r in (
        (canvas.p(*top), canvas.d(width * 0.4)),
        (canvas.p(*base), canvas.d(width * 0.5)),
    ):
        draw.ellipse([x - r, y - r, x + r, y + r], fill=255)
    body = blur(body, canvas.d(0.0015))

    outline = ImageChops.subtract(body.filter(ImageFilter.MaxFilter(_odd(canvas.d(0.014)))), body)
    paint(image, WOOD_DARK, outline, 0.9)
    paint(image, WOOD, body)
    # Light along the left edge, shade along the right edge.
    dx = canvas.d(width * 0.28)
    lit = ImageChops.subtract(body, shift(body, -dx, 0))
    shade = ImageChops.subtract(body, shift(body, dx, 0))
    paint(image, WOOD_LIGHT, blur(shade, canvas.d(0.004)), 0.9)
    paint(image, WOOD_DARK, blur(lit, canvas.d(0.004)), 0.55)
    # A few grain lines.
    grain = Image.new("L", size, 0)
    gdraw = ImageDraw.Draw(grain)
    for k, (f0, f1) in enumerate(((0.15, 0.45), (0.55, 0.8), (0.3, 0.62))):
        side = (-0.12, 0.1, 0.02)[k] * width
        a = _along(base, top, f0, side)
        b = _along(base, top, f1, side)
        gdraw.line([canvas.p(*a), canvas.p(*b)], fill=255, width=max(1, int(canvas.d(0.004))))
    paint(image, WOOD_DARK, ImageChops.multiply(blur(grain, canvas.d(0.002)), body), 0.45)
    # The cut end.
    tx, ty = canvas.p(*top)
    r = canvas.d(width * 0.36)
    cut = Image.new("L", size, 0)
    ImageDraw.Draw(cut).ellipse([tx - r, ty - r * 0.55, tx + r, ty + r * 0.55], fill=255)
    paint(image, WOOD_CUT, blur(cut, canvas.d(0.002)), 0.95)


def _along(base, top, fraction, side):
    (bx, by), (tx, ty) = base, top
    length = math.hypot(tx - bx, ty - by)
    nx, ny = -(ty - by) / length, (tx - bx) / length
    return (bx + (tx - bx) * fraction + nx * side, by + (ty - by) * fraction + ny * side)


def _odd(value):
    value = max(3, int(value))
    return value if value % 2 else value + 1


def cast_shadow(image, canvas, shapes, opacity=0.3):
    """Soft shadow of standing shapes, thrown towards the bottom right."""
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    for kind, data in shapes:
        if kind == "stick":
            base, top, width = data
            bx, by = base
            tx, ty = top
            # The shadow of a standing stick lies on the ground.
            end = (bx + (by - ty) * 0.5 + (tx - bx) * 0.2, by + (by - ty) * 0.22)
            draw.polygon(stick_polygon(canvas, base, end, width * 0.9, width * 0.6), fill=255)
        else:
            (x, y), rx, ry = data
            px, py = canvas.p(x + rx * 0.35, y + ry * 0.55)
            draw.ellipse(
                [px - canvas.d(rx), py - canvas.d(ry * 0.8), px + canvas.d(rx), py + canvas.d(ry * 0.8)],
                fill=255,
            )
    paint(image, SHADOW, blur(mask, canvas.d(0.008)), opacity)


def draw_pebble(image, canvas, center, rx, ry):
    size = image.size
    cx, cy = canvas.p(*center)
    box = [cx - canvas.d(rx), cy - canvas.d(ry), cx + canvas.d(rx), cy + canvas.d(ry)]
    body = Image.new("L", size, 0)
    ImageDraw.Draw(body).ellipse(box, fill=255)
    body = blur(body, canvas.d(0.002))
    paint(image, STONE_DARK, body)
    # Radial light from the top left.
    light = Image.new("L", size, 0)
    lr = canvas.d(rx * 0.95)
    lx, ly = cx - canvas.d(rx * 0.3), cy - canvas.d(ry * 0.35)
    ImageDraw.Draw(light).ellipse([lx - lr, ly - lr * 0.85, lx + lr, ly + lr * 0.85], fill=255)
    paint(image, STONE, ImageChops.multiply(blur(light, canvas.d(rx * 0.35)), body))
    spot = Image.new("L", size, 0)
    sr = canvas.d(rx * 0.32)
    sx, sy = cx - canvas.d(rx * 0.38), cy - canvas.d(ry * 0.45)
    ImageDraw.Draw(spot).ellipse([sx - sr, sy - sr * 0.7, sx + sr, sy + sr * 0.7], fill=255)
    paint(image, STONE_LIGHT, ImageChops.multiply(blur(spot, canvas.d(rx * 0.22)), body), 0.9)


def draw_cord(image, canvas, at, width):
    """The indigo cord binding the two sticks of a Sultan."""
    size = image.size
    x, y = at
    band = Image.new("L", size, 0)
    draw = ImageDraw.Draw(band)
    half = width * 1.05
    # Three turns around the crossing.
    for dy in (-0.019, 0.0, 0.019):
        a, b = canvas.p(x - half, y + dy - 0.004), canvas.p(x + half, y + dy + 0.004)
        draw.line([a, b], fill=255, width=int(canvas.d(0.017)))
    # The loose ends, blown to the right.
    for dx, dy in ((0.0, 0.0), (0.012, 0.018)):
        points = [
            canvas.p(x + half * 0.8 + dx * 0.3, y + 0.012 + dy * 0.3),
            canvas.p(x + half + 0.03 + dx, y + 0.045 + dy),
            canvas.p(x + half + 0.035 + dx, y + 0.075 + dy),
        ]
        draw.line(points, fill=255, width=int(canvas.d(0.011)), joint="curve")
    band = blur(band, canvas.d(0.0015))
    outline = ImageChops.subtract(band.filter(ImageFilter.MaxFilter(_odd(canvas.d(0.01)))), band)
    paint(image, (18, 30, 52), outline, 0.8)
    paint(image, INDIGO, band)
    lit = ImageChops.subtract(band, shift(band, 0, canvas.d(0.006)))
    paint(image, INDIGO_LIGHT, blur(lit, canvas.d(0.002)), 0.85)


SULTAN_LEFT = ((0.43, 0.6), (0.6, 0.2))
SULTAN_RIGHT = ((0.57, 0.6), (0.4, 0.2))
STICK_WIDTH = 0.056
CROSSING = (0.5, 0.435)
PEBBLE = ((CENTER[0] - HALF + 0.01, CENTER[1] + HALF - 0.015), 0.085, 0.07)


def foreground(size=MASTER):
    canvas = Canvas(size)
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cast_shadow(
        image,
        canvas,
        [
            ("stick", (*SULTAN_LEFT, STICK_WIDTH)),
            ("stick", (*SULTAN_RIGHT, STICK_WIDTH)),
            ("pebble", PEBBLE),
        ],
    )
    # Contact shadows where the sticks enter the sand.
    for base, _ in (SULTAN_LEFT, SULTAN_RIGHT):
        bx, by = canvas.p(*base)
        r = canvas.d(0.04)
        spot = Image.new("L", image.size, 0)
        ImageDraw.Draw(spot).ellipse([bx - r, by - r * 0.4, bx + r * 1.2, by + r * 0.5], fill=255)
        paint(image, SHADOW, blur(spot, canvas.d(0.01)), 0.4)
    draw_pebble(image, canvas, *PEBBLE)
    draw_stick(image, canvas, *SULTAN_LEFT, STICK_WIDTH)
    draw_stick(image, canvas, *SULTAN_RIGHT, STICK_WIDTH)
    draw_cord(image, canvas, CROSSING, STICK_WIDTH)
    return image


def monochrome(size=MASTER):
    """A one-colour silhouette, which Android 13+ tints for themed icons."""
    canvas = Canvas(size)
    mask = grooves(canvas, 0.03)
    # Keep the board light and the pieces solid.
    mask = mask.point(lambda v: int(v * 0.55))
    pieces = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(pieces)
    for base, top in (SULTAN_LEFT, SULTAN_RIGHT):
        draw.polygon(stick_polygon(canvas, base, top, STICK_WIDTH * 1.25, STICK_WIDTH), fill=255)
    (x, y), rx, ry = PEBBLE
    cx, cy = canvas.p(x, y)
    draw.ellipse([cx - canvas.d(rx), cy - canvas.d(ry), cx + canvas.d(rx), cy + canvas.d(ry)], fill=255)
    # Clear a gap around the pieces so they read against the lines.
    gap = pieces.filter(ImageFilter.MaxFilter(_odd(canvas.d(0.03))))
    mask = ImageChops.subtract(mask, gap)
    mask = ImageChops.lighter(mask, pieces)
    image = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    image.putalpha(mask)
    return image


# --- Compositions ----------------------------------------------------------


def full_layer(size=MASTER):
    image = background(size)
    image.alpha_composite(foreground(size))
    return image


def window(layer):
    """The part of a 108 dp layer that launchers show (72 dp)."""
    size = layer.size[0]
    margin = round(size * (LAYER_DP - WINDOW_DP) / 2 / LAYER_DP)
    return layer.crop((margin, margin, size - margin, size - margin))


def rounded(image, radius_fraction, supersample=4):
    size = image.size[0]
    big = size * supersample
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, big - 1, big - 1], radius=big * radius_fraction, fill=255
    )
    mask = mask.resize((size, size), Image.LANCZOS)
    result = image.copy()
    result.putalpha(ImageChops.multiply(result.getchannel("A"), mask))
    return result


def circle(image, supersample=4):
    size = image.size[0]
    big = size * supersample
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, big - 1, big - 1], fill=255)
    mask = mask.resize((size, size), Image.LANCZOS)
    result = image.copy()
    result.putalpha(ImageChops.multiply(result.getchannel("A"), mask))
    return result


def legacy_icon(icon, px, shape):
    """Android 7 icons: the shape with a small margin and a soft shadow."""
    big = px * 4
    inner = round(big * 0.84)
    art = icon.resize((inner, inner), Image.LANCZOS)
    art = rounded(art, 0.2) if shape == "square" else circle(art)
    canvas = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    offset = (big - inner) // 2
    shadow.paste((0, 0, 0, 90), (offset, offset + big // 48), art.getchannel("A"))
    canvas.alpha_composite(blur(shadow, big / 64))
    canvas.alpha_composite(art, (offset, offset))
    return canvas.resize((px, px), Image.LANCZOS)


def save(image, path, **options):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True, **options)
    print("wrote", path.relative_to(ROOT))


def display_font(size, weight=700):
    font = ImageFont.truetype(str(FONT), size, layout_engine=ImageFont.Layout.RAQM)
    font.set_variation_by_axes([weight])
    return font


def feature_graphic(icon):
    """1024 x 500: the logo and the name on a wide stretch of sand."""
    width, height = 1024, 500
    scale = 2
    W, H = width * scale, height * scale
    sand_tile = sand(W, seed=11).crop((0, (W - H) // 2, W, (W + H) // 2))
    image = sand_tile.copy()
    # A darker band at the bottom and left, towards the evening.
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    shade = np.clip((x / W - 0.55) * -0.5, 0, 0.25) + np.clip((y / H - 0.6) * 0.6, 0, 0.2)
    paint(image, SHADOW, Image.fromarray((shade * 255).astype(np.uint8)), 1.0)
    # The logo.
    logo_size = round(H * 0.68)
    logo = rounded(icon.resize((logo_size, logo_size), Image.LANCZOS), 0.22)
    lx, ly = round(W * 0.07), (H - logo_size) // 2
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow.paste((50, 25, 5, 120), (lx + 10, ly + 24), logo.getchannel("A"))
    image.alpha_composite(blur(shadow, 28))
    image.alpha_composite(logo, (lx, ly))
    # The name.
    draw = ImageDraw.Draw(image)
    text_x = lx + logo_size + round(W * 0.06)
    arabic = display_font(round(H * 0.3))
    latin = display_font(round(H * 0.105), 600)
    tagline = display_font(round(H * 0.064), 500)
    ink = (52, 38, 26)
    draw.text((text_x, round(H * 0.12)), NAME_AR, font=arabic, fill=(31, 58, 95), direction="rtl", language="ar")
    draw.text(
        (text_x + 6, round(H * 0.53)),
        " ".join(NAME_LATIN),
        font=latin,
        fill=ink,
    )
    draw.text((text_x + 6, round(H * 0.72)), "Le Dhamet mauritanien", font=tagline, fill=ink)
    draw.text((text_x + 6, round(H * 0.8)), "لعبة ظامت الموريتانية", font=tagline, fill=ink, direction="rtl", language="ar")
    return image.resize((width, height), Image.LANCZOS).convert("RGB")


def main():
    back = background()
    fore = foreground()
    mono = monochrome()
    full = back.copy()
    full.alpha_composite(fore)
    icon = window(full)  # the square, full-bleed icon

    res = "android/app/src/main/res"
    for density, factor in DENSITIES.items():
        layer_px = round(LAYER_DP * factor)
        for name, image in (("background", back), ("foreground", fore), ("monochrome", mono)):
            out = image.resize((layer_px, layer_px), Image.LANCZOS)
            if name == "background":
                out = out.convert("RGB")
            save(out, f"{res}/mipmap-{density}/ic_launcher_{name}.png")
        icon_px = round(48 * factor)
        save(legacy_icon(icon, icon_px, "square"), f"{res}/mipmap-{density}/ic_launcher.png")
        save(legacy_icon(icon, icon_px, "round"), f"{res}/mipmap-{density}/ic_launcher_round.png")
        # Launch screen before Android 12: the logo, 128 dp.
        splash_px = round(128 * factor)
        save(
            rounded(icon.resize((splash_px, splash_px), Image.LANCZOS), 0.22),
            f"{res}/drawable-{density}/splash_logo.png",
        )

    # iOS: opaque squares, iOS rounds them itself.
    appiconset = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((appiconset / "Contents.json").read_text())
    for entry in contents["images"]:
        points = float(entry["size"].split("x")[0])
        px = round(points * int(entry["scale"].rstrip("x")))
        out = icon.resize((px, px), Image.LANCZOS).convert("RGB")
        save(out, appiconset.relative_to(ROOT) / entry["filename"])

    save(rounded(icon.resize((512, 512), Image.LANCZOS), 0.22), "assets/images/logo.png")
    # Google Play: a full square (Play applies its own mask), as a 32-bit
    # PNG.
    save(icon.resize((512, 512), Image.LANCZOS), "deploiement/google-play/icon_512.png")
    save(feature_graphic(icon), "deploiement/google-play/feature_graphic_1024x500.png")


if __name__ == "__main__":
    main()
