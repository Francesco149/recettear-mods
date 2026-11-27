#!/usr/bin/env python3
"""hirefresh.py — the high-refresh showcase video from the owner's camera recording of the monitor.

Source (not in the repo): a 180 fps phone recording of a 144 Hz VG248QE, stored as 59.94 fps (so the file plays at
1/3 speed).  It shows, in order: stock 60, display mod Frame Rate Auto (144 Hz, vsync), 240 fps with vsync off.

  tools/showcase/hirefresh.py SRC.MOV [-o OUTDIR] [--fps 60|180|both] [--preview]

Every comparison is a full-screen wipe (owner 2026-11-27: easier to notice than side by side): title · real time
stock → 144 → 240 · slow motion (1/3, the file's own speed) stock → 144 → 240 on ONE timeline — the three recordings
of the same door → shelves turn, aligned by motion-energy cross-correlation, so the turn carries on across each wipe
and only the frame rate changes · end card.  Output OUTDIR/hirefresh_60.mp4: the real-time part blends the three
camera frames behind each output frame (what the eye integrates in 1/60 s); `--fps 180` keeps every camera frame.
"""
import argparse, os, subprocess, sys

FONT_B = "/usr/share/fonts/TTF/Roboto-Bold.ttf"
FONT_M = "/usr/share/fonts/TTF/Roboto-Medium.ttf"
FILE_FPS = "60000/1001"         # the file's frame rate; the camera's = 3×
CAM_FPS = "180000/1001"

LABEL = {
    "stock": "Stock 60 fps",
    "144": "Auto: 144 Hz (vsync)",
    "240": "240 fps, vsync off",
}
SUB = {
    "stock": "the game as shipped",
    "144": "interpolated, one frame per refresh",
    "240": "interpolated; tears on a 144 Hz panel",
}
# file seconds where each clip starts
RT = (("stock", 17.0), ("144", 47.0), ("240", 88.0))          # real time: separate looks around the shop
SLOW = (("stock", 20.39), ("144", 52.8), ("240", 89.17))      # the same turn in all three (one timeline)
RT_EACH, SLOW_EACH, FADE = 4.0, 3.0, 0.5                      # seconds on screen per clip / per wipe


def esc(s):
    return s.replace("\\", "\\\\").replace(":", "\\:").replace("'", "’").replace("%", "\\%")


def text(s, x, y, size, font=FONT_B, color="white", box=True, extra=""):
    b = ":box=1:boxcolor=black@0.55:boxborderw=14" if box else ""
    return f"drawtext=fontfile={font}:text='{esc(s)}':x={x}:y={y}:fontsize={size}:fontcolor={color}{b}{extra}"


def timing(kind, fps):
    """filters after trim: real time or slow motion, at the output rate"""
    if kind == "rt":
        if fps == 60:   # blend the 3 camera frames of each 1/60 s, keep one
            return f"setpts=PTS-STARTPTS,tmix=frames=3,framestep=3,setpts=N/({FILE_FPS})/TB"
        return f"setpts=N/({CAM_FPS})/TB"
    out = FILE_FPS if fps == 60 else CAM_FPS
    return f"setpts=PTS-STARTPTS,fps={out}"


def pane(i, mode, start, length, kind, fps):
    f = f"[0:v]trim=start={start}:duration={length},{timing(kind, fps)}"
    f += "," + text(LABEL[mode], 28, 28, 44)
    f += "," + text(SUB[mode], 28, 98, 28, FONT_M)
    return f + f"[p{i}]"


def banner(kind, fps):
    if kind == "rt":
        s = "REAL TIME" + (" (3 camera frames blended per video frame)" if fps == 60 else " (every camera frame)")
        return text(s, "(w-text_w)/2", "h-th-48", 38)
    return (text("SLOW MOTION — 1/3 speed (180 fps camera)", "(w-text_w)/2", "h-th-100", 38) + "," +
            text("a new picture: stock every 3rd camera frame · 144 Hz 4 of 5 · 240 every one", "(w-text_w)/2",
                 "h-th-40", 28, FONT_M))


def wipe(clips, kind, each, fps, continuous):
    """three full-screen clips, wiping left at each·1 and each·2 (on-screen seconds).  continuous: clip k starts
    where the timeline is (its base + k·each), so one motion carries on across the wipes"""
    scale = 3 if kind == "rt" else 1        # file seconds per on-screen second
    parts = []
    for k, (m, base) in enumerate(clips):
        length = each + (FADE if k < 2 else 0)
        start = base + (k * each * scale if continuous else 0)
        parts.append(pane(k, m, start, length * scale, kind, fps))
    g = ";".join(parts)
    g += f";[p0][p1]xfade=transition=wipeleft:duration={FADE}:offset={each}[x1]"
    g += f";[x1][p2]xfade=transition=wipeleft:duration={FADE}:offset={2 * each},{banner(kind, fps)}[v]"
    return g


def card(lines, secs, fps):
    out = FILE_FPS if fps == 60 else CAM_FPS
    g = f"color=c=0x101014:s=1920x1080:r={out}:d={secs}"
    hs = [size * 1.9 for _, size, _ in lines]
    y = 540 - sum(hs) / 2
    for (s, size, font), h in zip(lines, hs):
        g += "," + text(s, "(w-text_w)/2", int(y), size, font, box=False)
        y += h
    g += f",fade=t=in:st=0:d=0.4,fade=t=out:st={secs - 0.4}:d=0.4[v]"
    return g


def run(cmd):
    r = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
    if r.returncode:
        sys.exit(r.stderr[-3000:])


def render(src, outdir, fps, preview):
    parts = os.path.join(outdir, f"parts_{fps}")
    os.makedirs(parts, exist_ok=True)
    rate = FILE_FPS if fps == 60 else CAM_FPS
    enc = ["-c:v", "libx264", "-preset", "veryfast" if preview else "slow", "-crf", "24" if preview else "15",
           "-pix_fmt", "yuv420p", "-r", rate, "-an"]
    title = card([("Recettear Mod Loader — high refresh", 64, FONT_B),
                  ("Above 60 Hz the loader interpolates between the game's 60 ticks per second", 34, FONT_M),
                  ("Filmed at 180 fps off a 144 Hz monitor (VG248QE)", 30, FONT_M)]
                 + ([("Real time at 60 fps: each video frame blends 3 camera frames, so the extra frames show as smooth blur.", 26, FONT_M)]
                    if fps == 60 else []), 5.0, fps)
    end = card([("Display Settings  >  Frame Rate: Auto", 52, FONT_B),
                ("follows the monitor; the game logic stays at 60", 34, FONT_M)], 3.0, fps)
    jobs = [("00_title", None, title),
            ("01_wipe_rt", src, wipe(RT, "rt", RT_EACH, fps, False)),
            ("02_wipe_slow", src, wipe(SLOW, "slow", SLOW_EACH, fps, True)),
            ("03_end", None, end)]
    names = []
    for name, inp, graph in jobs:
        out = os.path.join(parts, name + ".mp4")
        cmd = ["ffmpeg", "-v", "error", "-y"]
        if inp:
            cmd += ["-i", inp, "-filter_complex", graph, "-map", "[v]"]
        else:
            cmd += ["-filter_complex", graph, "-map", "[v]"]
        print(f"  {fps} fps: {name}", flush=True)
        run(cmd + enc + [out])
        names.append(out)
    lst = os.path.join(parts, "list.txt")
    open(lst, "w").write("".join(f"file '{n}'\n" for n in names))
    final = os.path.join(outdir, f"hirefresh_{fps}{'_preview' if preview else ''}.mp4")
    run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", "-movflags", "+faststart", final])
    print(final)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src")
    ap.add_argument("-o", "--outdir", default=os.path.expanduser("~/Videos/showcase"))
    ap.add_argument("--fps", default="60", choices=["60", "180", "both"])
    ap.add_argument("--preview", action="store_true", help="fast encode")
    a = ap.parse_args()
    os.makedirs(a.outdir, exist_ok=True)
    for f in ([60, 180] if a.fps == "both" else [int(a.fps)]):
        render(a.src, a.outdir, f, a.preview)


if __name__ == "__main__":
    main()
