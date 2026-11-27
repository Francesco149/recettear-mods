#!/usr/bin/env python3
"""Wardrobe authoring: run the shipped rules (mods/wardrobe/regions.txt) over the user's own extracted images
with the loader's own kernel (rr.py → librecolor.so) and render sheets for human review.  Nothing derived is
ever written into the repo: sheets go wherever -o says (default: the scratch dir given).

  wardrobe.py overlay --src DIR -o out_dir [--only GLOB]       original | region map | each region isolated
  wardrobe.py sheet   --src DIR -o out.png [--palettes P,...]  every image × Original + palettes
  wardrobe.py lab --src DIR IMAGE X Y [X Y ...]                LAB of pixels (3×3 median) for seeds
"""
import argparse, fnmatch, os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(__file__))
import rr

HERE = os.path.dirname(os.path.abspath(__file__))
RULES = os.path.join(HERE, '../../mods/wardrobe/regions.txt')
PALETTES = os.path.join(HERE, '../../mods/wardrobe/palettes.txt')
COL = [(255, 60, 60), (60, 200, 255), (255, 220, 0), (0, 230, 120), (255, 120, 255), (140, 90, 255),
       (255, 150, 40), (40, 90, 200), (200, 255, 120), (160, 60, 20), (255, 255, 255), (0, 120, 60),
       (120, 120, 120), (80, 80, 80)]


def load_palettes(path=PALETTES):
    """palettes.txt: 'palette NAME' then 'REGION #rrggbb' lines"""
    pals, cur = {}, None
    for ln in open(path):
        ln = '' if ln.strip().startswith('#') else ln.strip()
        if not ln:
            continue
        t = ln.split()
        if t[0] == 'palette':
            cur = pals.setdefault(' '.join(t[1:]), {})
        elif cur is not None and len(t) >= 2:
            cur[t[0]] = t[1] if t[1].startswith('#') else '#' + t[1]
    return pals


def images(rules, src, only=None):
    out = []
    for g in rules.images:
        hits = sorted(p for p in walk(src) if fnmatch.fnmatchcase(p, g))
        for p in hits:
            if (not only or fnmatch.fnmatchcase(p, only)) and rules.match(p) == rules.images.index(g):
                out.append(p)
    return out


def walk(src):
    for d, _, fs in os.walk(src):
        for f in fs:
            yield os.path.relpath(os.path.join(d, f), src).replace('\\', '/').lower()


def load(src, p):
    d = rr.decode(open(os.path.join(src, p), 'rb').read())
    rgba, w, h, k = d
    return rgba, w, h


def to_img(rgba, w, h, bg=(70, 70, 70)):
    im = Image.frombytes('RGBA', (w, h), rgba)
    # BMP key → transparent for viewing
    px = im.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if (r, g, b) == (0, 255, 0):
                px[x, y] = (0, 0, 0, 0)
    base = Image.new('RGBA', (w, h), bg + (255,))
    base.alpha_composite(im)
    return base.convert('RGB')


def cmd_overlay(a):
    R = rr.Rules(open(a.rules).read())
    os.makedirs(a.o, exist_ok=True)
    for p in images(R, a.src, a.only):
        rgba, w, h = load(a.src, p)
        seg, wt, n = R.segment(R.match(p), rgba, w, h)
        orig = to_img(rgba, w, h)
        m = orig.copy().convert('L').convert('RGB')
        mp = m.load()
        for i in range(w * h):
            g = seg[i]
            if g != 255:
                k = wt[i] / 255 * 0.8
                c = COL[g % len(COL)]
                x, y = i % w, i // w
                o = mp[x, y]
                mp[x, y] = tuple(int(o[j] * (1 - k) + c[j] * k) for j in range(3))
        sc = a.scale
        sheet = Image.new('RGB', (w * 2 * sc, h * sc + 16 * len(R.regions) // 4 + 20), (30, 30, 30))
        sheet.paste(orig.resize((w * sc, h * sc), Image.NEAREST), (0, 0))
        sheet.paste(m.resize((w * sc, h * sc), Image.NEAREST), (w * sc, 0))
        d = ImageDraw.Draw(sheet)
        for i, (rid, nm, hid) in enumerate(R.regions):
            x, y = (i % 4) * 160 + 4, h * sc + 4 + (i // 4) * 16
            d.rectangle((x, y, x + 10, y + 10), fill=COL[i % len(COL)])
            d.text((x + 14, y), rid, fill=(255, 255, 255))
        out = os.path.join(a.o, p.replace('/', '_') + '.png')
        sheet.save(out)
        print(out, n)


def cmd_sheet(a):
    R = rr.Rules(open(a.rules).read())
    pals = load_palettes(a.palettes)
    names = ['Original'] + (a.pick.split(',') if a.pick else list(pals))
    imgs = images(R, a.src, a.only)
    T = a.thumb
    rows = []
    for p in imgs:
        rgba, w, h = load(a.src, p)
        seg, wt, _ = R.segment(R.match(p), rgba, w, h)
        row = []
        for nm in names:
            if nm == 'Original':
                out, ch = rgba, 0
            else:
                out, ch = R.apply(seg, wt, rgba, w, h, pals[nm])
            im = to_img(out, w, h)
            sc = min(T / w, T / h)
            row.append(im.resize((max(1, int(w * sc)), max(1, int(h * sc))), Image.LANCZOS))
        rows.append((p, row))
    W = T * len(names) + 10
    sheet = Image.new('RGB', (W, (T + 14) * len(rows) + 16), (40, 40, 40))
    d = ImageDraw.Draw(sheet)
    for j, nm in enumerate(names):
        d.text((j * T + 4, 2), nm, fill=(255, 255, 0))
    for i, (p, row) in enumerate(rows):
        y = 16 + i * (T + 14)
        for j, im in enumerate(row):
            sheet.paste(im, (j * T, y))
        d.text((4, y + T), p, fill=(200, 200, 200))
    sheet.save(a.o)
    print(a.o, len(rows), 'images ×', len(names))


def cmd_lab(a):
    rgba, w, h = load(a.src, a.image)
    v = list(map(int, a.xy))
    for x, y in zip(v[::2], v[1::2]):
        px = []
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                i = ((y + dy) * w + x + dx) * 4
                px.append(tuple(rgba[i:i + 3]))
        px.sort(key=sum)
        r, g, b = px[4]
        print(x, y, (r, g, b), ' '.join('%.0f' % c for c in rr.lab(r, g, b)))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rules', default=RULES)
    ap.add_argument('--palettes', default=PALETTES)
    ap.add_argument('--src', required=True, help='the user\'s extracted game data (bmp/… paths under it)')
    sp = ap.add_subparsers(dest='cmd', required=True)
    o = sp.add_parser('overlay'); o.add_argument('-o', required=True); o.add_argument('--only'); o.add_argument('--scale', type=int, default=1)
    s = sp.add_parser('sheet'); s.add_argument('-o', required=True); s.add_argument('--only'); s.add_argument('--pick'); s.add_argument('--thumb', type=int, default=200)
    l = sp.add_parser('lab'); l.add_argument('image'); l.add_argument('xy', nargs='+')
    a = ap.parse_args()
    {'overlay': cmd_overlay, 'sheet': cmd_sheet, 'lab': cmd_lab}[a.cmd](a)


if __name__ == '__main__':
    main()


def residue(R, src, p, k=12):
    """k-means (LAB) of opaque pixels no region took: what the rules miss"""
    import random
    rgba, w, h = load(src, p)
    seg, wt, _ = R.segment(R.match(p), rgba, w, h)
    pts = []
    for i in range(w * h):
        r, g, b, al = rgba[i * 4:i * 4 + 4]
        if al > 200 and seg[i] == 255 and (r, g, b) != (0, 255, 0):
            pts.append((rr.lab(r, g, b), i))
    random.seed(1)
    if not pts:
        return []
    cs = [c for c, _ in random.sample(pts, min(k, len(pts)))]
    for _ in range(12):
        acc = [[0, 0, 0, 0, None] for _ in cs]
        for c, i in pts:
            j = min(range(len(cs)), key=lambda j: sum((c[t] - cs[j][t]) ** 2 for t in range(3)))
            a = acc[j]; a[0] += c[0]; a[1] += c[1]; a[2] += c[2]; a[3] += 1; a[4] = a[4] or i
        cs = [(a[0] / a[3], a[1] / a[3], a[2] / a[3]) if a[3] else cs[j] for j, a in enumerate(acc)]
    return sorted(((acc[j][3], cs[j], (acc[j][4] or 0) % w, (acc[j][4] or 0) // w) for j in range(len(cs))), reverse=True)


if __name__ == '__main__' and len(sys.argv) > 1 and sys.argv[1] == 'residue':
    pass
