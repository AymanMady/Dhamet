"""Edits the Arabic demo video of Dhametna from the film of the app.

Usage: python3 tool/marketing/compose_video.py [--voice FILE | --audio FILE | --silent]
                                               [--formats 9x16,4x5,16x9]

Run by tool/marketing/render.sh, after the film of the app
(test/marketing/demo_video_test.dart). Reads build/demo_video/app.mkv and
build/demo_video/timeline.json and writes marketing/video/:
- dhametna-demo-9x16.mp4   Reels, Stories, WhatsApp status (1080 x 1920);
- dhametna-demo-4x5.mp4    Facebook and Instagram feed (1080 x 1350);
- dhametna-demo-16x9.mp4   YouTube, e.g. for the Google Play listing
  (1920 x 1080);
- dhametna-demo-miniature-<format>.jpg   a cover image for each video.

Each video: an opening card, the app in a phone with an Arabic caption per
scene and a finger on each tap, the strengths of the app, and a closing
card. The music is synthesised here, so it has no rights to clear. --voice
lays a recorded voice-over on it (the music is lowered), --audio replaces it
with another sound track and --silent leaves the video without sound. A
voice-over starts with the video: see marketing/05-video.md for its text.

Requires ffmpeg, numpy, Pillow with libraqm, and the fonts made by
tool/store/make_screenshot_fonts.py.
"""

import argparse
import json
import math
import subprocess
import sys
import wave
from multiprocessing import Pool
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tool/brand"))
import generate_brand_assets as brand  # noqa: E402

# Titles in the app's display face, Reem Kufi; other lines in its text face,
# Roboto with Noto Sans Arabic, as prepared for the store screenshots by
# tool/store/make_screenshot_fonts.py.
TEXT_FONTS = ROOT / "build/store_fonts"
FILM = ROOT / "build/demo_video"
OUT = ROOT / "marketing/video"
FPS = 30
RATE = 48000

# Colours, after lib/app/theme/app_colors.dart.
SAND50 = (251, 247, 239)
SAND300 = (217, 196, 158)
INDIGO = (31, 58, 95)
GOLD = (201, 150, 43)
GOLD_LIGHT = (232, 195, 106)
INK = (52, 38, 26)
NIGHT = (18, 20, 26)

# One caption per scene of the film (see the test): a title and a line.
# The game words are the traditional ones: عود، بعرة، ظايمة.
CAPTIONS = {
    "splash": ("ظامت، لعبتنا التقليدية", "الآن على هاتفك"),
    "home": ("ظامت، لعبتنا التقليدية", "الآن على هاتفك"),
    "local": ("العب مع صديقك", "على الهاتف نفسه: 40 عودًا ضد 40 بعرة"),
    "ai_setup": ("أو تحدَّ الحاسوب", "أربعة مستويات، من سهل إلى خبير"),
    "ai_move": ("المس عودك", "فتظهر لك النقلات الممكنة"),
    "must_capture": ("الأكل إجباري", "وعليك أن تأكل أكثر ما يمكن"),
    "dhayma": ("ستّ بعرات في نقلة واحدة!", "ووصل العود إلى الصف الأخير: صار ظايمة"),
    "flying": ("الظايمة تأكل من بعيد", "وتمشي على الخط كله"),
    "tutorial": ("تعلّم القواعد خطوة بخطوة", "دروس وتمارين على الرقعة"),
    "history": ("تابع تقدّمك", "سجلّ مبارياتك وإحصاءاتك"),
}

STRENGTHS = [
    "مجانية وبلا إعلانات",
    "تعمل دون إنترنت",
    "أربعة مستويات ضد الحاسوب",
    "بالعربية والفرنسية والإنجليزية",
]

INTRO = 2.6  # seconds
STRENGTHS_CARD = 3.2
OUTRO = 3.6
FADE = 10  # frames of a cross-fade

# Where things go in each format: the phone (height and centre of the
# screen) and the caption (centre and maximum width), in pixels; "unit"
# scales the type.
FORMATS = {
    "9x16": dict(size=(1080, 1920), phone_h=1300, phone_c=(540, 1210), caption_c=(540, 375), caption_w=980, unit=1.0),
    "4x5": dict(size=(1080, 1350), phone_h=1010, phone_c=(540, 832), caption_c=(540, 170), caption_w=1000, unit=0.78),
    "16x9": dict(size=(1920, 1080), phone_h=1000, phone_c=(600, 540), caption_c=(1330, 540), caption_w=980, unit=0.95),
}


def font(size, weight=700):
    return brand.display_font(round(size), weight)


def text_font(size, weight="Medium"):
    return ImageFont.truetype(str(TEXT_FONTS / f"RobotoArabic-{weight}.ttf"), round(size), layout_engine=ImageFont.Layout.RAQM)


def ease(t):
    t = min(max(t, 0.0), 1.0)
    return t * t * (3 - 2 * t)


def text_image(text, face, colour, max_width=None):
    """[text] set right to left in [face], cut into lines if needed."""
    words = text.split()
    lines = [words[0]]
    for word in words[1:]:
        candidate = lines[-1] + " " + word
        if max_width and face.getlength(candidate, direction="rtl", language="ar") > max_width:
            lines.append(word)
        else:
            lines[-1] = candidate
    ascent, descent = face.getmetrics()
    line_h = round((ascent + descent) * 1.08)
    widths = [math.ceil(face.getlength(line, direction="rtl", language="ar")) for line in lines]
    image = Image.new("RGBA", (max(widths) + 8, line_h * len(lines) + 8), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for i, (line, width) in enumerate(zip(lines, widths)):
        x = (image.width - width) // 2
        draw.text((x, 4 + i * line_h), line, font=face, fill=colour, direction="rtl", language="ar")
    return image


def shadowed(image, radius, offset, opacity):
    """[image] over its own soft shadow, on a larger transparent canvas."""
    pad = radius * 3
    canvas = Image.new("RGBA", (image.width + 2 * pad, image.height + 2 * pad), (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow.paste((20, 12, 4, round(255 * opacity)), (pad + offset[0], pad + offset[1]), image.getchannel("A"))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(radius)))
    canvas.alpha_composite(image, (pad, pad))
    return canvas, pad


def plate(title, line, unit, max_width):
    """A caption: the title and its line on a pale sand plate."""
    title_img = text_image(title, font(74 * unit), INDIGO, max_width - 90 * unit)
    line_img = text_image(line, text_font(40 * unit), INK, max_width - 90 * unit)
    pad_x, pad_y, gap = round(44 * unit), round(26 * unit), round(4 * unit)
    width = max(title_img.width, line_img.width) + 2 * pad_x
    height = title_img.height + gap + line_img.height + 2 * pad_y
    card = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(card)
    radius = round(34 * unit)
    draw.rounded_rectangle([0, 0, width - 1, height - 1], radius, fill=SAND50 + (240,), outline=SAND300 + (255,), width=max(2, round(3 * unit)))
    card.alpha_composite(title_img, ((width - title_img.width) // 2, pad_y))
    card.alpha_composite(line_img, ((width - line_img.width) // 2, pad_y + title_img.height + gap))
    return shadowed(card, round(18 * unit), (0, round(10 * unit)), 0.45)


def photo(size, blur_radius, darken):
    """The reference photo (a game in the sand), covering [size]."""
    source = Image.open(ROOT / "assets/images/scene.jpg").convert("RGB")
    width, height = size
    scale = max(width / source.width, height / source.height) * 1.12
    image = source.resize((round(source.width * scale), round(source.height * scale)), Image.LANCZOS)
    image = image.filter(ImageFilter.GaussianBlur(blur_radius))
    left, top = (image.width - width) // 2, (image.height - height) // 2
    image = image.crop((left, top, left + width, top + height))
    shade = Image.new("RGB", size, (28, 18, 8))
    return Image.blend(image, shade, darken)


def logo(size):
    icon = brand.window(brand.full_layer(1536)).resize((size, size), Image.LANCZOS)
    return shadowed(brand.rounded(icon, 0.22), round(size / 14), (0, round(size / 24)), 0.5)


def paste(base, overlay, centre, alpha=1.0, scale=1.0):
    """Pastes the RGBA [overlay] centred on [centre], faded by [alpha]."""
    if alpha <= 0:
        return
    if scale != 1.0:
        overlay = overlay.resize((max(1, round(overlay.width * scale)), max(1, round(overlay.height * scale))), Image.BILINEAR)
    mask = overlay.getchannel("A")
    if alpha < 1:
        mask = mask.point(lambda a: round(a * alpha))
    x = round(centre[0] - overlay.width / 2)
    y = round(centre[1] - overlay.height / 2)
    base.paste(overlay.convert("RGB"), (x, y), mask)


class Phone:
    """The phone in which the app is shown, on its background."""

    def __init__(self, spec, background):
        self.spec = spec
        unit = spec["unit"]
        height = spec["phone_h"]
        bezel = round(height * 0.014)
        self.screen_h = height - 2 * bezel
        self.screen_w = round(self.screen_h * 9 / 16)
        cx, cy = spec["phone_c"]
        self.screen_x = cx - self.screen_w // 2
        self.screen_y = cy - self.screen_h // 2
        outer = (self.screen_x - bezel, self.screen_y - bezel, self.screen_x + self.screen_w + bezel, self.screen_y + self.screen_h + bezel)
        radius = round(self.screen_w * 0.11)
        # The phone body, with its shadow, drawn once on the background.
        body = Image.new("RGBA", (outer[2] - outer[0], outer[3] - outer[1]), (0, 0, 0, 0))
        ImageDraw.Draw(body).rounded_rectangle([0, 0, body.width - 1, body.height - 1], radius + bezel, fill=NIGHT + (255,), outline=(70, 74, 86, 255), width=max(2, round(3 * unit)))
        body, pad = shadowed(body, round(28 * unit), (0, round(22 * unit)), 0.6)
        self.base = background.copy()
        self.base.paste(body.convert("RGB"), (outer[0] - pad, outer[1] - pad), body.getchannel("A"))
        big = Image.new("L", (self.screen_w * 3, self.screen_h * 3), 0)
        ImageDraw.Draw(big).rounded_rectangle([0, 0, big.width - 1, big.height - 1], radius * 3, fill=255)
        self.mask = big.resize((self.screen_w, self.screen_h), Image.LANCZOS)
        self.scale = self.screen_w / 360

    def frame(self, app):
        image = self.base.copy()
        screen = app.resize((self.screen_w, self.screen_h), Image.BICUBIC)
        image.paste(screen, (self.screen_x, self.screen_y), self.mask)
        return image

    def point(self, x, y):
        return (self.screen_x + x * self.scale, self.screen_y + y * self.scale)


def finger(image, centre, radius, press, ring):
    """A fingertip: a pale disc while pressing, then a widening ring."""
    size = round(radius * 4.4)
    patch = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(patch)
    c = size / 2
    if press > 0:
        r = radius * (1.12 - 0.12 * press)
        draw.ellipse([c - r, c - r, c + r, c + r], fill=(255, 255, 255, round(110 * press)), outline=(255, 255, 255, round(230 * press)), width=max(2, round(radius / 9)))
    if 0 < ring < 1:
        r = radius * (1 + 1.0 * ring)
        draw.ellipse([c - r, c - r, c + r, c + r], outline=(255, 255, 255, round(200 * (1 - ring))), width=max(2, round(radius / 7)))
    paste(image, patch, centre)


class Film:
    """The frames of the film of the app, read in order."""

    def __init__(self):
        self.timeline = json.loads((FILM / "timeline.json").read_text())
        self.width, self.height = self.timeline["size"]
        self.process = subprocess.Popen(
            ["ffmpeg", "-v", "error", "-i", str(FILM / "app.mkv"), "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
            stdout=subprocess.PIPE,
        )

    def frames(self):
        size = self.width * self.height * 3
        while True:
            data = self.process.stdout.read(size)
            if len(data) < size:
                break
            yield Image.frombuffer("RGB", (self.width, self.height), data, "raw", "RGB", 0, 1)
        self.process.wait()


def touches(timeline, frame):
    """The fingertips to draw on the film's [frame]: (x, y, press, ring)."""
    result = []
    for tap in timeline["taps"]:
        d = frame - tap["frame"]
        if -6 <= d <= 14:
            press = ease((d + 6) / 4) if d <= 1 else 1 - ease((d - 1) / 5)
            ring = (d - 1) / 12 if d >= 1 else 0
            result.append((tap["x"], tap["y"], press, ring))
    for drag in timeline["drags"]:
        points = drag["points"]
        d = frame - drag["frame"]
        if -6 <= d < len(points) + 6:
            x, y = points[min(max(d, 0), len(points) - 1)]
            press = ease((d + 6) / 5) if d < 0 else 1 - ease((d - len(points)) / 6) if d >= len(points) else 1
            result.append((x, y, press, 0))
    return result


def caption_at(timeline, frame):
    """The caption shown on [frame], with its time in and time left."""
    scenes = timeline["scenes"]
    for i, scene in enumerate(scenes):
        if scene["start"] <= frame < scene["end"]:
            caption = CAPTIONS[scene["id"]]
            start, end = scene["start"], scene["end"]
            # Scenes with the same caption share it.
            j = i
            while j > 0 and CAPTIONS[scenes[j - 1]["id"]] == caption:
                j -= 1
                start = scenes[j]["start"]
            j = i
            while j + 1 < len(scenes) and CAPTIONS[scenes[j + 1]["id"]] == caption:
                j += 1
                end = scenes[j]["end"]
            last = end == timeline["frames"]
            return caption, frame - start, (10**6 if last else end - frame)
    return None, 0, 0


# The cards before and after the app.


def intro_card(size, unit):
    background = photo(size, 2.5, 0.38)
    w, h = size
    shade = np.zeros((h, w), np.float32)
    shade += np.clip((np.arange(h)[:, None] / h - 0.25) * 1.1, 0, 0.65)
    over = Image.fromarray((shade * 255).astype(np.uint8))
    dark = Image.new("RGB", size, (16, 10, 4))
    background.paste(dark, (0, 0), over)
    vertical = h > w
    icon = logo(round(300 * unit if vertical else 260 * unit))
    title = shadowed(text_image("ظامتنا", font(190 * unit), SAND50), round(12 * unit), (0, round(6 * unit)), 0.6)[0]
    line1 = shadowed(text_image("لعبة ظامت الموريتانية", font(68 * unit, 600), GOLD_LIGHT), round(10 * unit), (0, round(4 * unit)), 0.6)[0]
    line2 = shadowed(text_image("الآن على هاتفك", text_font(52 * unit), SAND50), round(10 * unit), (0, round(4 * unit)), 0.6)[0]
    cy = h * (0.5 if vertical else 0.47)
    layout = [
        (icon[0], cy - 330 * unit, 0.0),
        (title, cy + 10 * unit, 0.35),
        (line1, cy + 205 * unit, 0.7),
        (line2, cy + 300 * unit, 0.95),
    ]

    def draw(t):
        zoom = 1 + 0.06 * t / INTRO
        image = background.resize((round(w * zoom), round(h * zoom)), Image.BILINEAR)
        left, top = (image.width - w) // 2, (image.height - h) // 2
        image = image.crop((left, top, left + w, top + h))
        for element, y, delay in layout:
            p = ease((t - delay) / 0.6)
            paste(image, element, (w / 2, y + (1 - p) * 40 * unit), p)
        return image

    return draw


def check_mark(unit):
    size = round(76 * unit)
    image = Image.new("RGBA", (size * 3, size * 3), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.ellipse([0, 0, size * 3 - 1, size * 3 - 1], fill=GOLD + (255,))
    s = size * 3
    draw.line([(s * 0.27, s * 0.52), (s * 0.44, s * 0.68), (s * 0.74, s * 0.34)], fill=SAND50 + (255,), width=round(s * 0.1), joint="curve")
    return image.resize((size, size), Image.LANCZOS)


def strengths_card(size, unit):
    background = photo(size, 14, 0.5)
    w, h = size
    title = text_image("ظامتنا", font(120 * unit), INDIGO)
    rows = []
    for text in STRENGTHS:
        label = text_image(text, text_font(48 * unit), INK)
        mark = check_mark(unit)
        gap = round(26 * unit)
        row = Image.new("RGBA", (label.width + gap + mark.width, max(label.height, mark.height)), (0, 0, 0, 0))
        # Right to left: the mark, then the words.
        row.alpha_composite(mark, (row.width - mark.width, (row.height - mark.height) // 2))
        row.alpha_composite(label, (0, (row.height - label.height) // 2))
        rows.append(row)
    row_w = max(row.width for row in rows)
    pad = round(60 * unit)
    row_gap = round(30 * unit)
    card_w = max(row_w, title.width) + 2 * pad
    card_h = title.height + round(20 * unit) + sum(row.height for row in rows) + row_gap * (len(rows) - 1) + 2 * pad
    card = Image.new("RGBA", (card_w, card_h), (0, 0, 0, 0))
    ImageDraw.Draw(card).rounded_rectangle([0, 0, card_w - 1, card_h - 1], round(44 * unit), fill=SAND50 + (245,), outline=SAND300 + (255,), width=max(2, round(3 * unit)))
    card.alpha_composite(title, ((card_w - title.width) // 2, pad - round(10 * unit)))
    card_img, card_pad = shadowed(card, round(26 * unit), (0, round(16 * unit)), 0.5)
    y = pad + title.height + round(20 * unit)
    placed = []
    for row in rows:
        # Aligned on the right, as Arabic reads.
        x = card_w - pad - row.width
        placed.append((row, card_pad + x + row.width / 2, card_pad + y + row.height / 2))
        y += row.height + row_gap

    def draw(t):
        image = background.copy()
        p = ease(t / 0.5)
        layer = card_img.copy()
        for i, (row, x, y) in enumerate(placed):
            q = ease((t - 0.35 - 0.3 * i) / 0.45)
            if q > 0:
                faded = row.copy()
                faded.putalpha(row.getchannel("A").point(lambda a: round(a * q)))
                layer.alpha_composite(faded, (round(x - row.width / 2 + (1 - q) * 30 * unit), round(y - row.height / 2)))
        paste(image, layer, (w / 2, h / 2 + (1 - p) * 40 * unit), p)
        return image

    return draw


def outro_card(size, unit):
    background = photo(size, 3, 0.5)
    w, h = size
    vertical = h > w
    if not vertical:
        unit *= 0.8  # the whole column must fit in the height
    icon = logo(round(280 * unit))[0]
    title = shadowed(text_image("ظامتنا", font(170 * unit), SAND50), round(12 * unit), (0, round(6 * unit)), 0.6)[0]
    latin_face = font(54 * unit, 600)
    latin_text = " ".join("DHAMETNA")
    latin = Image.new("RGBA", (math.ceil(latin_face.getlength(latin_text)) + 8, round(80 * unit)), (0, 0, 0, 0))
    ImageDraw.Draw(latin).text((4, 4), latin_text, font=latin_face, fill=GOLD_LIGHT)
    # The call to action: a gold button.
    label = text_image("حمّلها مجانًا", font(96 * unit), INDIGO)
    button = Image.new("RGBA", (label.width + round(150 * unit), label.height + round(50 * unit)), (0, 0, 0, 0))
    ImageDraw.Draw(button).rounded_rectangle([0, 0, button.width - 1, button.height - 1], button.height // 2, fill=GOLD_LIGHT + (255,))
    button.alpha_composite(label, ((button.width - label.width) // 2, (button.height - label.height) // 2))
    button = shadowed(button, round(16 * unit), (0, round(8 * unit)), 0.5)[0]
    store = shadowed(text_image("على Google Play", text_font(58 * unit), SAND50), round(10 * unit), (0, round(4 * unit)), 0.6)[0]
    cy = h * (0.47 if vertical else 0.45)
    layout = [
        (icon, cy - 380 * unit, 0.0),
        (title, cy - 70 * unit, 0.2),
        (latin, cy + 80 * unit, 0.35),
        (button, cy + 270 * unit, 0.6),
        (store, cy + 430 * unit, 0.8),
    ]

    def draw(t):
        image = background.copy()
        for element, y, delay in layout:
            p = ease((t - delay) / 0.55)
            scale = 1.0
            if element is button and t > 1.4:
                scale = 1 + 0.035 * math.sin((t - 1.4) * 2 * math.pi / 1.1)
            paste(image, element, (w / 2, y + (1 - p) * 40 * unit), p, scale)
        return image

    return draw


# Sound.


def pluck(freq, length, rate=RATE, brightness=1.0):
    """A plucked string, like a tidinit: decaying harmonics."""
    t = np.arange(int(length * rate)) / rate
    tone = np.zeros_like(t)
    for k in range(1, 11):
        amplitude = (1 / k**1.15) * (0.6 if k % 2 == 0 else 1.0) * brightness ** (k - 1)
        decay = 2.2 + 0.9 * k
        tone += amplitude * np.exp(-decay * t) * np.sin(2 * np.pi * freq * k * t + k)
    attack = np.minimum(t / 0.004, 1)
    return tone * attack / 2.2


def drum(length, rate=RATE, low=True):
    """The tbal: a deep "doum", or a dry "tek" on the rim."""
    t = np.arange(int(length * rate)) / rate
    rng = np.random.default_rng(3 if low else 5)
    if low:
        freq = 52 + 46 * np.exp(-t * 28)
        phase = 2 * np.pi * np.cumsum(freq) / rate
        body = np.sin(phase) * np.exp(-t * 7.5)
        noise = rng.normal(0, 1, len(t)) * np.exp(-t * 60) * 0.15
        return body + noise
    noise = rng.normal(0, 1, len(t))
    noise = np.diff(noise, prepend=0)  # brighter
    return noise * np.exp(-t * 55) * 0.5


def music(duration, groove, ending, taps):
    """About 92 beats a minute in D minor pentatonic: a plucked pattern, a
    bass and the tbal from [groove] to [ending] (seconds), and a soft click
    on each tap."""
    n = int(duration * RATE)
    left = np.zeros(n)
    right = np.zeros(n)

    def add(sound, at, gain, pan=0.0):
        start = int(at * RATE)
        if start >= n:
            return
        sound = sound[: n - start]
        left[start : start + len(sound)] += sound * gain * (1 - pan) / 1.0
        right[start : start + len(sound)] += sound * gain * (1 + pan) / 1.0

    note = {"A3": 220.0, "C4": 261.63, "D4": 293.66, "F4": 349.23, "G4": 392.0, "A4": 440.0, "C5": 523.25, "D5": 587.33}
    bars = [
        ("D", ["D4", "A4", "F4", "A4", "G4", "A4", "F4", "A4"]),
        ("D", ["D4", "A4", "F4", "A4", "C5", "A4", "G4", "F4"]),
        ("C", ["C4", "G4", "F4", "G4", "C5", "G4", "F4", "G4"]),
        ("A", ["A3", "G4", "F4", "G4", "A4", "G4", "F4", "D4"]),
    ]
    bass = {"D": 73.42, "C": 65.41, "A": 55.0}
    beat = 60 / 92
    t = 0.0
    bar = 0
    while t < duration - 1.2:
        root, pattern = bars[bar % len(bars)]
        in_groove = groove <= t < ending
        for i, name in enumerate(pattern):
            at = t + i * beat / 2
            gain = 0.16 if in_groove else 0.11
            add(pluck(note[name], 1.6, brightness=0.8), at, gain * (1.0 if i % 2 == 0 else 0.75), 0.25 if i % 4 < 2 else -0.25)
        if in_groove or t >= ending:
            add(pluck(bass[root], 2.6, brightness=0.6), t, 0.42)
        if in_groove:
            for b in range(4):
                add(drum(0.6), t + b * beat, 0.5 if b in (0, 2) else 0.32)
                add(drum(0.12, low=False), t + b * beat + beat / 2, 0.07, 0.3)
            add(drum(0.12, low=False), t + 3.75 * beat, 0.05, -0.3)
        t += 4 * beat
        bar += 1
    # The last chord, ringing out.
    for name, delay in (("D4", 0), ("A4", 0.06), ("D5", 0.12)):
        add(pluck(note[name], 3.0, brightness=0.85), ending + delay, 0.2)
    add(pluck(bass["D"], 3.5, brightness=0.6), ending, 0.45)
    # A soft drone throughout.
    tt = np.arange(n) / RATE
    swell = 0.5 + 0.5 * np.sin(2 * np.pi * tt / 7.0)
    left += 0.035 * (np.sin(2 * np.pi * 146.83 * tt) + 0.5 * np.sin(2 * np.pi * 220.0 * tt)) * (0.6 + 0.4 * swell)
    right += 0.035 * (np.sin(2 * np.pi * 147.2 * tt) + 0.5 * np.sin(2 * np.pi * 220.4 * tt)) * (0.6 + 0.4 * swell)
    click = np.sin(2 * np.pi * 1800 * np.arange(int(0.03 * RATE)) / RATE) * np.exp(-np.arange(int(0.03 * RATE)) / RATE * 160)
    for at in taps:
        add(click, at, 0.08)
    # Fades, then a gentle limit at -4 dBFS: music behind the pictures.
    fade_in = np.minimum(tt / 0.8, 1)
    fade_out = np.clip((duration - tt) / 2.2, 0, 1)
    stereo = np.stack([left, right], axis=1) * (fade_in * fade_out)[:, None]
    stereo /= np.abs(stereo).max()
    stereo = np.tanh(stereo * 1.4) / np.tanh(1.4) * 0.63
    return stereo


def write_wav(path, stereo):
    data = (stereo * 32767).astype("<i2")
    with wave.open(str(path), "wb") as out:
        out.setnchannels(2)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(data.tobytes())


# Editing.


def render(job):
    name, audio = job
    spec = FORMATS[name]
    size = spec["size"]
    unit = spec["unit"]
    film = Film()
    timeline = film.timeline
    background = photo(size, 16, 0.45)
    phone = Phone(spec, background)
    captions = {}
    out = OUT / f"dhametna-demo-{name}.mp4"
    command = ["ffmpeg", "-y", "-v", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{size[0]}x{size[1]}", "-r", str(FPS), "-i", "-"]
    if audio:
        command += ["-i", str(audio), "-c:a", "aac", "-b:a", "160k", "-ar", str(RATE), "-shortest"]
    command += ["-c:v", "libx264", "-preset", "slow", "-crf", "21", "-pix_fmt", "yuv420p", "-profile:v", "high", "-movflags", "+faststart", str(out)]
    encoder = subprocess.Popen(command, stdin=subprocess.PIPE)
    last = None
    thumbnail_frame = None
    count = 0

    def emit(image, fade_from=None, fade=0.0):
        nonlocal count
        if fade_from is not None and fade < 1:
            image = Image.blend(fade_from, image, ease(fade))
        encoder.stdin.write(image.tobytes())
        count += 1
        return image

    intro = intro_card(size, unit)
    for i in range(round(INTRO * FPS)):
        last = emit(intro(i / FPS))
    held = last
    for index, app in enumerate(film.frames()):
        image = phone.frame(app)
        for x, y, press, ring in touches(timeline, index):
            finger(image, phone.point(x, y), 22 * phone.scale, press, ring)
        caption, age, left = caption_at(timeline, index)
        if caption:
            if caption not in captions:
                captions[caption] = plate(*caption, unit, spec["caption_w"])
            card, _ = captions[caption]
            p = min(ease(age / 9), ease(left / 7))
            cx, cy = spec["caption_c"]
            paste(image, card, (cx, cy + (1 - p) * 30 * unit), p)
        cut = max((c for c in timeline["cuts"] if c <= index), default=None)
        if index < FADE:
            image = emit(image, held, (index + 1) / FADE)
        elif cut is not None and index - cut < FADE and last is not None:
            if index == cut:
                held = last
            image = emit(image, held, (index - cut + 1) / FADE)
        else:
            image = emit(image)
        last = image
        if index == thumbnail_at(timeline):
            thumbnail_frame = image.copy()
    held = last
    strengths = strengths_card(size, unit)
    for i in range(round(STRENGTHS_CARD * FPS)):
        last = emit(strengths(i / FPS), held, (i + 1) / FADE)
    held = last
    outro = outro_card(size, unit)
    for i in range(round(OUTRO * FPS)):
        last = emit(outro(i / FPS), held, (i + 1) / FADE)
    encoder.stdin.close()
    if encoder.wait() != 0:
        raise SystemExit(f"ffmpeg failed for {out.name}")
    if thumbnail_frame is not None:
        thumbnail_frame.save(OUT / f"dhametna-demo-miniature-{name}.jpg", quality=90)
    return f"{out.relative_to(ROOT)}: {count / FPS:.1f} s"


def thumbnail_at(timeline):
    """The cover: the rafle drawn on the board, with its caption."""
    for scene in timeline["scenes"]:
        if scene["id"] == "must_capture":
            taps = [tap["frame"] for tap in timeline["taps"] if scene["start"] <= tap["frame"] < scene["end"]]
            return taps[0] + 20 if taps else scene["start"] + 30
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--voice", type=Path, help="voice-over to lay on the music")
    parser.add_argument("--audio", type=Path, help="sound track to use instead of the music")
    parser.add_argument("--silent", action="store_true", help="no sound")
    parser.add_argument("--formats", default=",".join(FORMATS), help="formats to render, e.g. 9x16,4x5")
    args = parser.parse_args()
    timeline = json.loads((FILM / "timeline.json").read_text())
    OUT.mkdir(parents=True, exist_ok=True)
    app_seconds = timeline["frames"] / FPS
    duration = INTRO + app_seconds + STRENGTHS_CARD + OUTRO
    audio = None
    if args.audio:
        audio = args.audio.resolve()
    elif not args.silent:
        audio = FILM / "music.wav"
        taps = [INTRO + tap["frame"] / FPS for tap in timeline["taps"]]
        write_wav(audio, music(duration, INTRO, INTRO + app_seconds + STRENGTHS_CARD, taps))
        if args.voice:
            mix = FILM / "music_and_voice.wav"
            subprocess.run(
                ["ffmpeg", "-y", "-v", "error", "-i", str(audio), "-i", str(args.voice.resolve()), "-filter_complex",
                 f"[0:a]volume=0.3[m];[1:a]aresample={RATE},apad[v];[m][v]amix=inputs=2:duration=first:normalize=0[out]",
                 "-map", "[out]", "-ar", str(RATE), str(mix)],
                check=True,
            )
            audio = mix
    names = [name for name in args.formats.split(",") if name]
    for name in names:
        if name not in FORMATS:
            raise SystemExit(f"unknown format {name}: {', '.join(FORMATS)}")
    with Pool(len(names)) as pool:
        for line in pool.imap_unordered(render, [(name, audio) for name in names]):
            print("wrote", line)


if __name__ == "__main__":
    main()
