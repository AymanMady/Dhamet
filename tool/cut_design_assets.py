"""Cuts the game's images out of the reference art.

Usage: python3 tool/cut_design_assets.py design.jpeg assets/images

The reference image (1264 x 842) shows an asset library on the left and a
game scene in the middle. This script extracts:

- scene.jpg   the game scene, used as the background, with its "NEW GAME"
              planks and corner icons painted out;
- stick.png   the upper part of the wooden stick (the part a planted stick
              shows above the sand), cut out on transparency;
- pebble.png  the pebble, cut out on transparency;
- sand.jpg    the sand texture, evened out and rebuilt as a seamless tile;
- plank.png   a wooden plank without its text, for the buttons.

Requires numpy and opencv-python.
"""

import sys
from pathlib import Path

import cv2
import numpy as np

# Regions of the reference image, as (left, top, right, bottom).
SCENE = (455, 70, 939, 811)
STICK = (80, 80, 135, 410)
PEBBLE = (232, 92, 385, 250)
SAND = (18, 580, 205, 768)
PLANK = (811, 86, 926, 124)
# Parts of the scene painted out, relative to the scene.
SCENE_OVERLAYS = [
    (806 - 455, 82 - 70, 931 - 455, 130 - 70),  # top "NEW GAME" plank
    (784 - 455, 740 - 70, 926 - 455, 794 - 70),  # bottom "NEW GAME" plank
    (466 - 455, 76 - 70, 572 - 455, 130 - 70),  # corner icons
]


def crop(image, box):
    left, top, right, bottom = box
    return image[top:bottom, left:right].copy()


def cut_out(region):
    """Separates an object from the light, plain background around it."""
    border = np.concatenate(
        [region[0], region[-1], region[:, 0], region[:, -1]]
    ).astype(np.float32)
    background = np.median(border, axis=0)
    lab = cv2.cvtColor(region, cv2.COLOR_BGR2LAB).astype(np.float32)
    background_lab = cv2.cvtColor(
        background.reshape(1, 1, 3).astype(np.uint8), cv2.COLOR_BGR2LAB
    ).astype(np.float32)[0, 0]
    distance = np.linalg.norm(lab - background_lab, axis=2)
    mask = (distance > 16).astype(np.uint8)
    kernel = np.ones((3, 3), np.uint8)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=2)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(mask)
    largest = 1 + np.argmax(stats[1:, cv2.CC_STAT_AREA])
    mask = (labels == largest).astype(np.uint8)
    # Fill holes.
    flood = mask.copy()
    cv2.floodFill(flood, None, (0, 0), 1)
    mask = mask | (1 - flood)

    # Refine the edge with GrabCut, starting from that mask.
    grab = np.full(mask.shape, cv2.GC_PR_BGD, np.uint8)
    grab[cv2.dilate(mask, kernel, iterations=2) == 1] = cv2.GC_PR_FGD
    grab[cv2.erode(mask, kernel, iterations=3) == 1] = cv2.GC_FGD
    grab[cv2.dilate(mask, kernel, iterations=6) == 0] = cv2.GC_BGD
    models = (np.zeros((1, 65)), np.zeros((1, 65)))
    cv2.grabCut(region, grab, None, *models, 4, cv2.GC_INIT_WITH_MASK)
    mask = np.isin(grab, (cv2.GC_FGD, cv2.GC_PR_FGD)).astype(np.float32)

    # Soft edge, and edge colours freed from the light background.
    alpha = cv2.GaussianBlur(mask, (3, 3), 0.8)
    alpha = np.clip(alpha, 0, 1)
    colour = region.astype(np.float32)
    safe = np.maximum(alpha, 0.2)[..., None]
    colour = (colour - (1 - safe) * background) / safe
    colour = np.clip(colour, 0, 255)
    rgba = np.dstack([colour, alpha * 255]).astype(np.uint8)
    ys, xs = np.nonzero(alpha > 0.02)
    return rgba[ys.min() : ys.max() + 1, xs.min() : xs.max() + 1]


def planted_stick(stick):
    """Keeps the top of the stick: what shows above the sand."""
    height = stick.shape[0]
    return stick[: int(height * 0.42)]


def seamless_sand(sand, target, size=512, patch=72, seed=3):
    """Evens out the light, then rebuilds a larger texture from random
    pieces of the sample, wrapping around the edges so that it tiles
    without seams or visible symmetry. Its average colour becomes [target],
    the colour of the scene's sand, so that the board matches the scene."""
    image = sand.astype(np.float32)
    mean = image.reshape(-1, 3).mean(axis=0)
    flat = image - cv2.GaussianBlur(image, (0, 0), 10) + mean
    rng = np.random.default_rng(seed)
    window = np.outer(np.hanning(patch), np.hanning(patch)) ** 6 + 1e-6
    total = np.zeros((size, size, 3), np.float32)
    weight = np.zeros((size, size, 1), np.float32)
    step = patch // 3
    height, width = flat.shape[:2]
    for y in range(0, size, step):
        for x in range(0, size, step):
            top = rng.integers(0, height - patch)
            left = rng.integers(0, width - patch)
            piece = flat[top : top + patch, left : left + patch]
            w = window * rng.uniform(0.5, 1.5)
            rows = (np.arange(patch) + y + rng.integers(-4, 5)) % size
            cols = (np.arange(patch) + x + rng.integers(-4, 5)) % size
            total[np.ix_(rows, cols)] += piece * w[..., None]
            weight[np.ix_(rows, cols)] += w[..., None]
    out = total / weight
    # Blending softens the grain: give it back its contrast.
    scale = flat.reshape(-1, 3).std(axis=0) / out.reshape(-1, 3).std(axis=0)
    out = target + (out - mean) * scale
    return np.clip(out, 0, 255).astype(np.uint8)


def scene_without_overlays(scene):
    mask = np.zeros(scene.shape[:2], np.uint8)
    for left, top, right, bottom in SCENE_OVERLAYS:
        mask[top:bottom, left:right] = 255
    return cv2.inpaint(scene, mask, 9, cv2.INPAINT_TELEA)


def plank_without_text(plank):
    """Rebuilds the band of carved letters from the grain just above and
    below it (the grain runs along the plank), and cuts the plank's rounded
    shape."""
    height, width = plank.shape[:2]
    band_top, band_bottom = int(height * 0.28), int(height * 0.74)
    above = plank[int(height * 0.14) : band_top]
    below = plank[band_bottom : int(height * 0.88)]
    middle = (band_top + band_bottom) // 2
    clean = plank.copy()
    clean[band_top:middle] = cv2.resize(
        above, (width, middle - band_top), interpolation=cv2.INTER_LINEAR
    )
    clean[middle:band_bottom] = cv2.resize(
        below, (width, band_bottom - middle), interpolation=cv2.INTER_LINEAR
    )
    # Soften the joins.
    for row in (band_top, middle, band_bottom):
        joint = slice(max(row - 2, 0), min(row + 2, height))
        clean[joint] = cv2.GaussianBlur(clean, (1, 5), 0)[joint]
    shape = np.zeros((height, width), np.uint8)
    radius = int(height * 0.16)
    cv2.rectangle(shape, (radius, 0), (width - 1 - radius, height - 1), 255, -1)
    cv2.rectangle(shape, (0, radius), (width - 1, height - 1 - radius), 255, -1)
    for x in (radius, width - 1 - radius):
        for y in (radius, height - 1 - radius):
            cv2.circle(shape, (x, y), radius, 255, -1, cv2.LINE_AA)
    shape = cv2.GaussianBlur(shape, (3, 3), 0.7)
    return np.dstack([clean, shape])


def main():
    source, target = sys.argv[1], Path(sys.argv[2])
    target.mkdir(parents=True, exist_ok=True)
    image = cv2.imread(source)
    if image is None or image.shape[:2] != (842, 1264):
        sys.exit(f"{source}: expected the 1264 x 842 reference image")

    scene = scene_without_overlays(crop(image, SCENE))
    cv2.imwrite(str(target / "scene.jpg"), scene, [cv2.IMWRITE_JPEG_QUALITY, 92])
    stick = planted_stick(cut_out(crop(image, STICK)))
    cv2.imwrite(str(target / "stick.png"), stick)
    cv2.imwrite(str(target / "pebble.png"), cut_out(crop(image, PEBBLE)))
    # The sand of the scene around the drawn board.
    scene_sand = np.median(scene[380:560].reshape(-1, 3), axis=0)
    cv2.imwrite(
        str(target / "sand.jpg"),
        seamless_sand(crop(image, SAND), scene_sand),
        [cv2.IMWRITE_JPEG_QUALITY, 92],
    )
    cv2.imwrite(str(target / "plank.png"), plank_without_text(crop(image, PLANK)))
    for name in ("scene.jpg", "stick.png", "pebble.png", "sand.jpg", "plank.png"):
        shape = cv2.imread(str(target / name), cv2.IMREAD_UNCHANGED).shape
        print(f"{name}: {shape[1]} x {shape[0]}")


if __name__ == "__main__":
    main()
