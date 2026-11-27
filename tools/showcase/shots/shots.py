#!/usr/bin/env python3
"""shots.py SRC_DIR — the fetched BMPs of a showcase run (plan.lua) → docs/img/*.jpg (+ the wardrobe before / after
crop of Recette from the two low-camera shots)."""
import glob, os, sys
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
OUT = os.path.join(ROOT, "docs", "img")
src = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
for f in sorted(glob.glob(os.path.join(src, "*.bmp"))):
    name = os.path.splitext(os.path.basename(f))[0]
    Image.open(f).convert("RGB").save(os.path.join(OUT, name + ".jpg"), quality=88, optimize=True)
box = tuple(int(v) for v in (sys.argv[2:6] or (860, 780, 1160, 1080)))
a = Image.open(os.path.join(src, "camera_low.bmp")).convert("RGB").crop(box)
b = Image.open(os.path.join(src, "camera_low_midnight.bmp")).convert("RGB").crop(box)
k = 2
pair = Image.new("RGB", (a.width * k * 2 + 8, a.height * k), (255, 255, 255))
pair.paste(a.resize((a.width * k, a.height * k), Image.LANCZOS), (0, 0))
pair.paste(b.resize((b.width * k, b.height * k), Image.LANCZOS), (a.width * k + 8, 0))
pair.save(os.path.join(OUT, "wardrobe_before_after.jpg"), quality=90)
print(sorted(os.listdir(OUT)))
