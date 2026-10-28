"""Draws the images of the Dhametna Facebook Page, in Arabic.

Usage: python3 tool/marketing/facebook_visuals.py

Run by tool/marketing/render.sh, after the film of the app: the screens and
boards shown come from build/demo_video/app.mkv. Writes marketing/visuels/:
- photo-profil.png   720 x 720, the logo (Facebook shows it in a circle);
- couverture.png     1640 x 924, the cover photo, with everything that
  matters in the central band of 1640 x 624 that computers show;
- post-*.png         1080 x 1350 (4:5), the images of the first posts,
  listed in marketing/03-calendrier.md.

Requires ffmpeg, numpy, Pillow with libraqm, and the fonts made by
tool/store/make_screenshot_fonts.py.
"""

import json

from PIL import Image, ImageDraw

import compose_video as video
from compose_video import FILM, GOLD_LIGHT, INDIGO, INK, ROOT, SAND50, brand, font, paste, shadowed, text_font, text_image

OUT = ROOT / "marketing/visuels"
POST = (1080, 1350)


def film_frames(wanted):
    """The film's frames at the indices of [wanted] ({name: index})."""
    found = {}
    for index, frame in enumerate(video.Film().frames()):
        for name, at in wanted.items():
            if at == index:
                found[name] = frame.copy()
    missing = set(wanted) - set(found)
    if missing:
        raise SystemExit(f"frames missing from the film: {', '.join(sorted(missing))}")
    return found


def moments(timeline):
    """Where to take each screen in the film."""
    scenes = {scene["id"]: scene for scene in timeline["scenes"]}

    def taps(scene):
        return [tap["frame"] for tap in timeline["taps"] if scenes[scene]["start"] <= tap["frame"] < scenes[scene]["end"]]

    return {
        "home": scenes["home"]["start"] + 20,
        "opening": scenes["local"]["start"] + 20,
        "levels": taps("ai_setup")[1] + 18,  # "Hard" chosen
        "rafle": taps("must_capture")[0] + 25,  # the rafle shown on the board
        "dhayma": scenes["dhayma"]["start"] + 25,
        "flying": taps("flying")[0] + 20,  # the Dhayma's capture shown
        "history": timeline["frames"] - 1,
    }


def phone_shot(app, height, unit=1.0):
    """The app's [app] screen in a phone, with its shadow."""
    pad = round(110 * unit)
    width = round(height * 9 / 16) + 2 * pad
    canvas = Image.new("RGBA", (width, height + 2 * pad), (0, 0, 0, 0))
    spec = dict(unit=unit, phone_h=height, phone_c=(width // 2, canvas.height // 2))
    return video.Phone(spec, canvas).frame(app.convert("RGBA"))


def board_shot(app, width):
    """The board of a game screen, cut out, with rounded corners."""
    board = app.crop((3 * 6, 3 * 128, 3 * 354, 3 * 476)).resize((width, width), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (board.width * 2, board.height * 2), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, mask.width - 1, mask.height - 1], board.width // 10, fill=255)
    board.putalpha(mask.resize(board.size, Image.LANCZOS))
    return shadowed(board, 22, (0, 14), 0.45)[0]


def sand_background(size):
    side = max(size)
    image = brand.sand(side, seed=11).convert("RGB")
    left, top = (side - size[0]) // 2, (side - size[1]) // 2
    return image.crop((left, top, left + size[0], top + size[1]))


def dark_background(size):
    return video.photo(size, 6, 0.55)


def heading(image, title, line, y, dark=False, title_size=96, line_size=44, width=960):
    """A title and its line, centred, from height [y]; returns the bottom."""
    w = image.width
    title_img = text_image(title, font(title_size), SAND50 if dark else INDIGO, width)
    line_img = text_image(line, text_font(line_size), GOLD_LIGHT if dark else INK, width)
    if dark:
        title_img = shadowed(title_img, 10, (0, 5), 0.6)[0]
        line_img = shadowed(line_img, 8, (0, 3), 0.6)[0]
    paste(image, title_img, (w / 2, y + title_img.height / 2))
    y += title_img.height - (30 if dark else 0)
    paste(image, line_img, (w / 2, y + line_img.height / 2))
    return y + line_img.height


def signature(image, dark=False):
    """The logo and the name, at the bottom."""
    icon = brand.rounded(brand.window(brand.full_layer(768)).resize((84, 84), Image.LANCZOS), 0.22)
    name = text_image("ظامتنا", font(58), SAND50 if dark else INDIGO)
    latin_face = font(30, 600)
    latin = Image.new("RGBA", (round(latin_face.getlength("D H A M E T N A")) + 8, 44), (0, 0, 0, 0))
    ImageDraw.Draw(latin).text((4, 4), "D H A M E T N A", font=latin_face, fill=GOLD_LIGHT if dark else INK)
    gap = 18
    total = icon.width + gap + max(name.width, latin.width)
    x = (image.width - total) / 2
    y = image.height - 80
    paste(image, icon, (x + total - icon.width / 2, y))
    text_x = x + max(name.width, latin.width) / 2
    paste(image, name, (text_x, y - 16))
    paste(image, latin, (text_x, y + 30))


def pill(text, background, colour, size=46):
    label = text_image(text, text_font(size), colour)
    image = Image.new("RGBA", (label.width + 70, label.height + 26), (0, 0, 0, 0))
    ImageDraw.Draw(image).rounded_rectangle([0, 0, image.width - 1, image.height - 1], image.height // 2, fill=background + (255,))
    image.alpha_composite(label, ((image.width - label.width) // 2, (image.height - label.height) // 2))
    return image


def profile():
    # The full adaptive icon layer: its centre stays whole in a circle.
    return brand.full_layer(1440).resize((720, 720), Image.LANCZOS).convert("RGB")


def cover(frames):
    size = (1640, 924)
    image = sand_background(size)
    # Two phones on the left, the name on the right (Arabic reads from the
    # right). The profile picture covers the bottom left on computers.
    paste(image, phone_shot(frames["home"], 540), (380, 470))
    paste(image, phone_shot(frames["dhayma"], 580), (650, 455))
    right = 1210
    name = text_image("ظامتنا", font(200), INDIGO)
    paste(image, name, (right, 330))
    latin_face = font(52, 600)
    latin = Image.new("RGBA", (round(latin_face.getlength("D H A M E T N A")) + 8, 74), (0, 0, 0, 0))
    ImageDraw.Draw(latin).text((4, 4), "D H A M E T N A", font=latin_face, fill=INK)
    paste(image, latin, (right, 480))
    line = text_image("لعبة ظامت الموريتانية على هاتفك", text_font(42), INK)
    paste(image, line, (right, 560))
    paste(image, pill("مجانية • بلا إعلانات • دون إنترنت", INDIGO, SAND50, 34), (right, 650))
    return image


def post(background, title, line, shot, extra=None):
    """A 4:5 post: a heading, a picture and the signature."""
    dark = background == "dark"
    image = dark_background(POST) if dark else sand_background(POST)
    bottom = heading(image, title, line, 60, dark)
    space_top, space_bottom = bottom + 20, POST[1] - 150
    if extra is not None:
        space_bottom -= extra.height + 10
        paste(image, extra, (POST[0] / 2, space_bottom + extra.height / 2 + 5))
    # The shot's shadow may run over the margins, not the shot itself.
    room = space_bottom - space_top + 60
    if shot.height > room:
        shot = fit(shot, room)
    paste(image, shot, (POST[0] / 2, (space_top + space_bottom) / 2))
    signature(image, dark)
    return image


def fit(shot, height):
    """[shot] scaled to [height] pixels, shadow included."""
    return shot.resize((round(shot.width * height / shot.height), height), Image.LANCZOS)


def main():
    timeline = json.loads((FILM / "timeline.json").read_text())
    frames = film_frames(moments(timeline))
    OUT.mkdir(parents=True, exist_ok=True)

    def save(image, name):
        image.convert("RGB").save(OUT / name, optimize=True)
        print("wrote", (OUT / name).relative_to(ROOT))

    save(profile(), "photo-profil.png")
    save(cover(frames), "couverture.png")

    save(post("dark", "قريبًا…", "ظامت، لعبتنا التقليدية، على هاتفك", fit(phone_shot(frames["opening"], 760), 900)), "post-01-bientot.png")
    save(
        post(
            "sand",
            "كن من أوائل اللاعبين",
            "نبحث عن مختبرين لتطبيق ظامتنا قبل إطلاقه على Google Play",
            fit(phone_shot(frames["home"], 700), 780),
            pill("علِّق «أنا» أو راسلنا", INDIGO, SAND50),
        ),
        "post-02-testeurs.png",
    )
    save(post("sand", "الأكل إجباري", "وعليك أن تأكل أكثر ما يمكن: هنا ستّ بعرات في نقلة واحدة", board_shot(frames["rafle"], 860)), "post-03-regle-akl.png")
    save(
        post("sand", "الظايمة", "العود الذي يصل إلى الصف الأخير يصبح ظايمة، تمشي وتأكل من بعيد", board_shot(frames["flying"], 860)),
        "post-04-regle-dhayma.png",
    )
    phones = Image.new("RGBA", (1000, 860), (0, 0, 0, 0))
    paste(phones, phone_shot(frames["home"], 640), (330, 430))
    paste(phones, phone_shot(frames["rafle"], 680), (650, 430))
    save(
        post("dark", "متوفرة الآن!", "حمّل ظامتنا مجانًا على Google Play", phones, pill("مجانية • بلا إعلانات • دون إنترنت", GOLD_LIGHT, INDIGO)),
        "post-05-lancement.png",
    )
    save(
        post("sand", "هل تغلب الحاسوب؟", "أربعة مستويات: سهل، متوسط، صعب، خبير", fit(phone_shot(frames["levels"], 760), 860)),
        "post-06-defi.png",
    )
    save(post("sand", "تابع تقدّمك", "سجلّ مبارياتك وإحصاءاتك، حتى دون إنترنت", fit(phone_shot(frames["history"], 760), 860)), "post-07-historique.png")


if __name__ == "__main__":
    main()
