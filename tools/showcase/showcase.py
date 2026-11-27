#!/usr/bin/env python3
"""showcase.py — the showcase video: the scripted gameplay clips (video/plan.lua) + the slow-motion high-refresh wipe
from the owner's camera recording, captions over the footage (no cards on black), the game's shop music.

  tools/showcase/showcase.py CLIPS_DIR HIREFRESH.MOV MUSIC.wav [-o OUTDIR] [--preview] [--only SEG]

CLIPS_DIR = the fetched out/ of a video/ run (title, wide, display, free, fp, wpage, wardrobe, outro .mkv) + overlay_rt.mkv
(the overlay stretch of a plan_overlay --grab run: real time, so its fps line is the display's);
HIREFRESH.MOV = the camera recording hirefresh.py cuts (its slow-motion section is reused here); MUSIC.wav = the
user's own bgm/open.wav (looped as the game loops it).  Nothing derived from the game goes into the repo.
Output: OUTDIR/showcase_1080p60.mp4 (YouTube: x264 crf 15, AAC 320k), showcase_discord.mp4 (720p60, 2-pass, under
20 MB) and showcase_readme.mp4 (720p60, 2-pass, under 10 MB: GitHub's README upload limit).

Each segment is rendered on its own (clip + captions drawn with Pillow, animated by ffmpeg), then the segments are
cross-faded into one timeline.  Captions sit where the picture is idle (the void beside the shop, the blurred pause
background); the end plate lies over the last gameplay clip.
"""
import argparse, os, subprocess, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import hirefresh as hr

W, H, FPS = 1920, 1080, 60
FONT = "/usr/share/fonts/TTF/Roboto-%s.ttf"
AMBER, INK, CREAM, WHITE = (255, 184, 28), (22, 17, 12), (238, 226, 205), (255, 255, 255)
XF = 0.4                 # cross-fade between segments (s)
DISCORD_MB, README_MB = 19.0, 9.5
REPO = "github.com/Francesco149/recettear-mod-loader"


def font(weight, size):
    return ImageFont.truetype(FONT % weight, size)


def spaced(d, xy, s, f, fill, track):
    """letter-spaced text; returns its width"""
    x, y = xy
    for ch in s:
        d.text((x, y), ch, font=f, fill=fill)
        x += d.textlength(ch, font=f) + track
    return x - xy[0] - track


def spaced_w(d, s, f, track):
    return sum(d.textlength(ch, font=f) + track for ch in s) - track


def plate(w, h, radius=20, alpha=205, accent=True, pad=40):
    """a dark rounded plate with a soft shadow (+ an amber bar on its left edge); returns (image, origin of the plate)"""
    img = Image.new("RGBA", (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    sh = Image.new("L", img.size, 0)
    ImageDraw.Draw(sh).rounded_rectangle((pad, pad + 8, pad + w, pad + h + 8), radius, fill=150)
    img.putalpha(sh.filter(ImageFilter.GaussianBlur(16)))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((pad, pad, pad + w, pad + h), radius, fill=INK + (alpha,))
    if accent:
        d.rounded_rectangle((pad, pad, pad + 10, pad + h), 5, fill=AMBER + (255,))
    return img, pad


def chip(kicker, title, sub=None, title_size=50):
    """feature caption: amber kicker, bold title, one or two lines of detail"""
    fk, ft, fs = font("Bold", 21), font("Black", title_size), font("Medium", 27)
    probe = ImageDraw.Draw(Image.new("RGBA", (8, 8)))
    subs = sub.split("\n") if sub else []
    tw = max([spaced_w(probe, kicker.upper(), fk, 3), probe.textlength(title, font=ft)] +
             [probe.textlength(s, font=fs) for s in subs])
    w = int(tw) + 38 + 34
    h = 24 + 26 + 8 + int(title_size * 1.16) + (10 + 36 * len(subs) if subs else 0) + 22
    img, pad = plate(w, h)
    d = ImageDraw.Draw(img)
    x, y = pad + 38, pad + 24
    spaced(d, (x, y), kicker.upper(), fk, AMBER + (255,), 3)
    y += 26 + 8
    d.text((x, y - 6), title, font=ft, fill=WHITE + (255,))
    y += int(title_size * 1.16) + 10
    for s in subs:
        d.text((x, y - 4), s, font=fs, fill=CREAM + (255,))
        y += 36
    return img, pad, w, h


def pill(text, size=30, fill=AMBER, ink=INK):
    f = font("Bold", size)
    probe = ImageDraw.Draw(Image.new("RGBA", (8, 8)))
    w, h = int(probe.textlength(text, font=f)) + 44, int(size * 1.9)
    pad = 24
    img = Image.new("RGBA", (w + 2 * pad, h + 2 * pad), (0, 0, 0, 0))
    sh = Image.new("L", img.size, 0)
    ImageDraw.Draw(sh).rounded_rectangle((pad, pad + 5, pad + w, pad + h + 5), h // 2, fill=140)
    img.putalpha(sh.filter(ImageFilter.GaussianBlur(9)))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((pad, pad, pad + w, pad + h), h // 2, fill=fill + (245,))
    d.text((pad + 22, pad + h / 2), text, font=f, fill=ink + (255,), anchor="lm")
    return img, pad, w, h


def note(text, size=24):
    """small caption on a faint plate"""
    f = font("Medium", size)
    probe = ImageDraw.Draw(Image.new("RGBA", (8, 8)))
    w, h = int(probe.textlength(text, font=f)) + 36, int(size * 1.9)
    img, pad = plate(w, h, radius=h // 2, alpha=170, accent=False, pad=20)
    ImageDraw.Draw(img).text((pad + 18, pad + h / 2), text, font=f, fill=CREAM + (255,), anchor="lm")
    return img, pad, w, h


def headline(lines, sub, align="left"):
    """the opening / end plate: big two-weight title, amber rule, detail lines"""
    fb, fs = font("Black", 84), font("Medium", 30)
    probe = ImageDraw.Draw(Image.new("RGBA", (8, 8)))
    subs = sub.split("\n")
    tw = int(max([probe.textlength(s, font=fb) for s in lines] + [probe.textlength(s, font=fs) for s in subs]))
    w = tw + 2 * 48
    h = 40 + 92 * len(lines) + 30 + 40 * len(subs) + 34
    img, pad = plate(w, h, radius=26, alpha=215, accent=False)
    d = ImageDraw.Draw(img)

    def tx(s, f):
        return pad + (48 if align == "left" else (w - probe.textlength(s, font=f)) / 2)
    y = pad + 34
    for i, s in enumerate(lines):
        d.text((tx(s, fb), y), s, font=fb, fill=(AMBER if i == len(lines) - 1 and len(lines) > 1 else WHITE) + (255,))
        y += 92
    y += 10
    rx = pad + 48 if align == "left" else pad + w / 2 - 60
    d.rounded_rectangle((rx, y, rx + 120, y + 6), 3, fill=AMBER + (255,))
    y += 24
    for s in subs:
        d.text((tx(s, fs), y), s, font=fs, fill=CREAM + (255,))
        y += 40
    return img, pad, w, h


def place(card, anchor, mx=56, my=52, y=None):
    """top-left of the card image for an anchor: tr tl bl br bc c (+ explicit y)"""
    img, pad, w, h = card
    x = {"l": mx, "r": W - mx - w, "c": (W - w) // 2}[anchor[1] if len(anchor) > 1 else "c"]
    yy = {"t": my, "b": H - my - h, "c": (H - h) // 2}[anchor[0]]
    if y is not None:
        yy = y
    return x - pad, yy - pad


class Seg:
    """one segment: a clip (or a filter graph producing [v]) + overlays"""
    def __init__(self, name, dur):
        self.name, self.dur, self.ov, self.pre = name, dur, [], None

    def add(self, card, anchor, t0, t1=None, slide=44, **kw):
        t1 = self.dur - 0.25 if t1 is None else t1
        self.ov.append((card[0], place(card, anchor, **kw), t0, t1, slide if "r" in anchor else -slide if "l" in anchor else 0))
        return self


def render_seg(seg, inputs, graph, out, tmp, preview):
    """graph must end in [v] (W×H, FPS); overlays are faded + slid in on top"""
    cmd = ["ffmpeg", "-v", "error", "-y"] + inputs
    n = sum(1 for a in inputs if a == "-i")
    g, cur = graph, "v"
    for k, (img, (x, y), t0, t1, slide) in enumerate(seg.ov):
        p = os.path.join(tmp, f"{seg.name}_{k}.png")
        img.save(p)
        d = t1 - t0
        cmd += ["-loop", "1", "-framerate", str(FPS), "-t", f"{d:.3f}", "-i", p]
        g += (f";[{n + k}:v]format=rgba,fade=t=in:st=0:d=0.35:alpha=1,fade=t=out:st={d - 0.3:.3f}:d=0.3:alpha=1,"
              f"setpts=PTS+{t0:.3f}/TB[o{k}]")
        xe = f"{x}+{slide}*pow(1-min(1\\,(t-{t0:.3f})/0.45)\\,3)" if slide else str(x)
        g += f";[{cur}][o{k}]overlay=x='{xe}':y={y}:eof_action=pass:enable='between(t,{t0:.3f},{t1:.3f})'[w{k}]"
        cur = f"w{k}"
    g += f";[{cur}]format=yuv420p[out]"
    cmd += ["-filter_complex", g, "-map", "[out]", "-t", f"{seg.dur:.3f}", "-r", str(FPS), "-c:v", "libx264",
            "-preset", "veryfast" if preview else "fast", "-crf", "20" if preview else "10", "-pix_fmt", "yuv420p",
            "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709", "-an", out]
    r = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
    if r.returncode:
        sys.exit(f"{seg.name}: {r.stderr[-3000:]}")


def game(start, dur, extra=""):
    """a captured clip → [v]: RGB → BT.709"""
    return (f"[0:v]trim=start={start}:duration={dur + 0.1},setpts=PTS-STARTPTS,fps={FPS},"
            f"scale={W}:{H}:out_color_matrix=bt709:out_range=tv:flags=neighbor{extra},format=yuv444p[v]")


def build(clips, mov, a):
    """[(Seg, ffmpeg inputs, graph)]"""
    def clip(n):
        return ["-i", os.path.join(clips, n + ".mkv")]
    segs = []

    # 1 — the title screen: what this is; the unlocked menu
    s = Seg("01_title", 5.0)
    s.add(headline(["Recettear", "Mod Loader"], "quality-of-life + customisation mods\nfor the Steam release"), "cr", 0.35, 3.15, y=540)
    s.add(chip("mod · unlock-menu", "Full title menu", "New Game+, Survival and the rest,\nwhatever your saves hold"), "cr", 3.2, y=600)
    segs.append((s, clip("title"), game(0, s.dur)))

    # 2 — widescreen, live
    s = Seg("02_wide", 6.8)
    s.add(chip("mod · display", "Widescreen", "wider 3D view, HUD at the screen's edges"), "tr", 0.4)
    s.add(pill("4:3  ·  the game as shipped", fill=CREAM), "bc", 0.4, 2.83, my=40)
    s.add(pill("16:9  ·  switched live"), "bc", 2.83, my=40)
    segs.append((s, clip("wide"), game(0, s.dur)))

    # 3 — the Display Settings page, down to Frame Rate → Auto
    s = Seg("03_display", a.display_len)
    s.add(chip("mod · display", "Display Settings", "a page in the game's own Options menu:\nborderless, resolution, render scale, VSYNC"), "tr", 1.5)
    segs.append((s, clip("display"), game(a.display_start, s.dur)))

    # 4 — high refresh: the slow-motion three-way wipe from the camera recording (hirefresh.py's section, unlabelled)
    kind, length, cl = hr.SECTIONS[1]
    w = hr.WIPE[kind]
    g, cur, t = "", "p0", length
    for k, (mode, start) in enumerate(cl):
        g += (f"[0:v]trim=start={start}:duration={length + (w if k < len(cl) - 1 else 0)},setpts=PTS-STARTPTS,"
              f"fps={hr.FILE_FPS},{hr.GRADE},format=gbrp[p{k}];")
    for k in range(1, len(cl)):
        g += f"[{cur}][p{k}]xfade=transition=custom:duration={w}:offset={t}:expr='{hr.WIPE_EXPR}'[x{k}];"
        cur, t = f"x{k}", t + length
    g += f"[{cur}]setpts=N/{FPS}/TB,fps={FPS},format=yuv444p[v]"
    s = Seg("04_hirefresh", length * len(cl) * 60000 / 1001 / FPS - 0.05)
    s.add(chip("mod · display", "High refresh rate", "frames interpolated up to your display's rate;\nthe game's speed is unchanged"), "bl", 0.4)
    for k, lab in enumerate(["Stock  ·  60 fps", "Auto  ·  144 Hz", "240 fps  ·  VSYNC off"]):
        t0 = max(0.4, k * length * 0.999)
        s.add(pill(lab, fill=CREAM if k == 0 else AMBER), "tr", t0, min(s.dur - 0.25, (k + 1) * length * 0.999), slide=0)
    s.add(note("slow motion, 1/3 speed  ·  180 fps camera on a 144 Hz monitor"), "tr", 0.6, y=52 + 57 + 18)
    segs.append((s, ["-i", mov], g))

    # 5 — free camera
    s = Seg("05_free", 8.7)
    s.add(chip("mod · free-camera", "Free Camera", "turn, zoom and raise:\na third camera in the shop's own cycle"), "tr", 0.4)
    segs.append((s, clip("free"), game(0.3, s.dur)))

    # 6 — first person
    s = Seg("06_fp", a.fp_len)
    s.add(chip("mod · first-person", "First Person", "mouse look, WASD,\nfield of view on its own Options page"), "tr", 0.5)
    segs.append((s, clip("fp"), game(0, s.dur)))

    # 7 — the Wardrobe page
    s = Seg("07_wpage", a.wpage_len)
    s.add(chip("mod · wardrobe", "Wardrobe", "recolour Recette by region:\npresets or your own colours, live preview"), "tr", 0.4)
    segs.append((s, clip("wpage"), game(a.wpage_start, s.dur)))

    # 8 — the presets in the shop, a 2× inset on Recette
    s = Seg("08_wardrobe", 6.3)
    cx, cy = a.recette
    ins = (f",split[m][c];[c]crop=240:270:{cx - 120}:{cy - 150},scale=480:540:flags=neighbor,"
           f"pad=492:552:6:6:color=0xffb81c[i];[m][i]overlay=1372:300")
    s.add(chip("mod · wardrobe", "Everywhere she appears", "recoloured from your own game files as they load;\nthe artwork's shading is kept"), "tr", 0.4)
    for k, lab in enumerate(["Original", "Midnight", "Sakura", "Forest"]):
        t0 = max(0.4, (k * 84 + 1) / 60)
        s.add(pill(lab, size=28, fill=CREAM if k == 0 else AMBER), "tr", t0, min(s.dur - 0.25, ((k + 1) * 84 + 1) / 60),
              slide=0, mx=W - 1372 - 492 + 150, y=300 + 552 + 14)
    segs.append((s, clip("wardrobe"), game(0, s.dur, ins)))

    # 9 — the developer overlay
    s = Seg("09_overlay", 4.8)
    s.add(chip("the loader", "A mod API with the game's own data", "Lua mods, chained hooks, shop / item / customer state,\nan ImGui overlay (F10) for mod windows"), "cr", 0.4, y=372)
    segs.append((s, clip("overlay_rt"), game(0.3, s.dur)))

    # 10 — end plate over the last clip
    s = Seg("10_outro", 8.0)
    s.add(headline(["Recettear Mod Loader"], f"{REPO}\nfree + open source (MIT)  ·  you need your own copy of the game", "center"), "cc", 0.8, 7.9)
    dim = ",eq=brightness=-0.10:saturation=0.85,gblur=sigma=3:enable='gte(t,0.6)'"
    segs.append((s, clip("outro"), game(0, s.dur, dim)))
    return segs


def assemble(parts, durs, music, out, preview):
    """cross-fade the segments, lay the looped music under them"""
    cmd = ["ffmpeg", "-v", "error", "-y"]
    for p in parts:
        cmd += ["-i", p]
    cmd += ["-stream_loop", "-1", "-i", music]
    g, cur, t = "", "0:v", durs[0]
    for k in range(1, len(parts)):
        g += f"[{cur}][{k}:v]xfade=transition=fade:duration={XF}:offset={t - XF:.3f}[x{k}];"
        cur, t = f"x{k}", t + durs[k] - XF
    g += f"[{cur}]fade=t=in:st=0:d=0.5,fade=t=out:st={t - 0.6:.3f}:d=0.6,format=yuv420p[v];"
    g += f"[{len(parts)}:a]atrim=0:{t:.3f},volume=-4dB,afade=t=in:st=0:d=0.4,afade=t=out:st={t - 3:.3f}:d=3[a]"
    cmd += ["-filter_complex", g, "-map", "[v]", "-map", "[a]", "-t", f"{t:.3f}", "-r", str(FPS), "-c:v", "libx264",
            "-preset", "veryfast" if preview else "slow", "-crf", "22" if preview else "15", "-pix_fmt", "yuv420p",
            "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
            "-c:a", "aac", "-b:a", "320k", "-movflags", "+faststart", out]
    r = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
    if r.returncode:
        sys.exit(r.stderr[-3000:])
    return t


def small(final, out, dur, mb, height=720, fps=60, akb=128):
    """a 2-pass copy under `mb` MB"""
    kbps = int(mb * 8192 / dur * 0.97) - akb
    log = out + ".2pass"
    base = ["ffmpeg", "-v", "error", "-y", "-i", final, "-vf", f"fps={fps},scale=-2:{height}:flags=lanczos", "-c:v", "libx264",
            "-preset", "slower", "-b:v", f"{kbps}k", "-pix_fmt", "yuv420p", "-colorspace", "bt709", "-color_primaries",
            "bt709", "-color_trc", "bt709", "-passlogfile", log]
    for extra in (["-pass", "1", "-an", "-f", "mp4", os.devnull],
                  ["-pass", "2", "-c:a", "aac", "-b:a", f"{akb}k", "-movflags", "+faststart", out]):
        r = subprocess.run(base + extra, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
        if r.returncode:
            sys.exit(r.stderr[-3000:])
    for f in os.listdir(os.path.dirname(out)):
        if f.startswith(os.path.basename(log)):
            os.remove(os.path.join(os.path.dirname(out), f))
    print(out, f"{os.path.getsize(out) / 1048576:.1f} MB at {kbps} kb/s video, {height}p{fps}")


def copies(final, outdir, dur):
    """the two small copies: Discord (under 20 MB) and the GitHub README (its upload limit is 10 MB)"""
    small(final, os.path.join(outdir, "showcase_discord.mp4"), dur, DISCORD_MB)
    small(final, os.path.join(outdir, "showcase_readme.mp4"), dur, README_MB, akb=96)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("clips"); ap.add_argument("mov"); ap.add_argument("music")
    ap.add_argument("-o", "--outdir", default=os.path.expanduser("~/Videos/showcase"))
    ap.add_argument("--preview", action="store_true", help="fast encodes")
    ap.add_argument("--only", help="render one segment (name prefix) and stop")
    ap.add_argument("--copies", action="store_true", help="only re-encode the small copies from the existing master")
    # cut points that depend on the capture (seconds into the clip)
    ap.add_argument("--display-start", type=float, default=0.5); ap.add_argument("--display-len", type=float, default=6.9)
    ap.add_argument("--fp-len", type=float, default=7.6)
    ap.add_argument("--wpage-start", type=float, default=0.7); ap.add_argument("--wpage-len", type=float, default=4.6)
    ap.add_argument("--recette", type=int, nargs=2, default=(1015, 935), help="Recette's feet-ish centre in the wardrobe clip")
    a = ap.parse_args()
    if a.copies:
        final = os.path.join(a.outdir, "showcase_1080p60.mp4")
        dur = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", final],
                                   capture_output=True, text=True).stdout)
        return copies(final, a.outdir, dur)
    tmp = os.path.join(a.outdir, "parts_showcase" + ("_preview" if a.preview else ""))
    os.makedirs(tmp, exist_ok=True)
    parts, durs = [], []
    for seg, inputs, graph in build(a.clips, a.mov, a):
        out = os.path.join(tmp, seg.name + ".mp4")
        if a.only and not seg.name.startswith(a.only):
            parts.append(out); durs.append(seg.dur)
            continue
        print(" ", seg.name, flush=True)
        render_seg(seg, inputs, graph, out, tmp, a.preview)
        parts.append(out)
        durs.append(float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", out],
                                         capture_output=True, text=True).stdout or seg.dur))
    if a.only:
        return
    final = os.path.join(a.outdir, "showcase_1080p60" + ("_preview" if a.preview else "") + ".mp4")
    dur = assemble(parts, durs, a.music, final, a.preview)
    print(final, f"{dur:.1f} s  {os.path.getsize(final) / 1048576:.1f} MB")
    if not a.preview:
        copies(final, a.outdir, dur)


if __name__ == "__main__":
    main()
