#!/usr/bin/env python3
"""hirefresh.py — the high-refresh showcase video from the owner's camera recording of the monitor.

Source (not in the repo): a 180 fps phone recording of a 144 Hz VG248QE, stored as 59.94 fps (so the file plays at
1/3 speed).  It shows, in order: stock 60, display mod Frame Rate Auto (144 Hz, vsync), 240 fps with vsync off — the
owner ran the same mouse routine in each (144 ≈ stock + 32.4 s, 240 ≈ 144 + 36.4 s of file time).

  tools/showcase/hirefresh.py SRC.MOV [-o OUTDIR] [--fps 60|180] [--preview] [--small]

Every comparison is a wipe between the SAME movement (owner 2026-11-27): two three-way sections, stock → 144 → 240,
real time (a fast turn + a strafe) then slow motion (1/3, the strafe).  Each clip plays one stretch of the routine
from pause to pause (aligned by picture matching); the wipe runs while both sides are frozen on those pauses (A's
last frame, B's first), a white divider sweeping across — never mid-movement.  No title card; end card.
Output OUTDIR/hirefresh_60.mp4 (the real-time parts blend the 3 camera frames behind each video frame = what the eye
integrates in 1/60 s); --small also writes hirefresh_60_small.mp4 (2-pass, < 20 MB).
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
# pairs: (kind, (mode A, file s), (mode B, file s)) — A and B start on the same moment of the routine
# sections: (kind, length in file s, ((mode, file s start), …)) — the same stretch of the routine in each recording,
# pause to pause, aligned by picture matching (64×48 normalised thumbnails of the 4:3 middle, help box + HUD masked)
SECTIONS = [
    ("rt", 6.75, (("stock", 19.75), ("144", 51.58), ("240", 88.09))),     # a fast turn, then the strafe
    ("slow", 4.25, (("stock", 22.5), ("144", 54.12), ("240", 90.66))),    # the strafe
]
WIPE = 1.0                                     # on-screen seconds of each wipe (both sides frozen)
SMALL_MB = 19.0


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


def pane(i, mode, start, length, kind, fps, head, tail):
    """a clip with its label top-right (a wipe from the right shows the incoming label first), frozen `head` / `tail`
    on-screen seconds on its first / last frame"""
    f = f"[0:v]trim=start={start}:duration={length},{timing(kind, fps)}"
    x = "w-text_w-28"
    f += "," + text(LABEL[mode], x, 28, 44)
    f += "," + text(SUB[mode], x, 98, 28, FONT_M)
    if head or tail:
        f += f",tpad=start_mode=clone:start_duration={head}:stop_mode=clone:stop_duration={tail}"
    return f + f",format=gbrp[p{i}]"


def banner(kind, fps):
    if kind == "rt":
        s = "REAL TIME" + (" (3 camera frames blended per video frame)" if fps == 60 else " (every camera frame)")
        return text(s, "(w-text_w)/2", "h-th-48", 38)
    return (text("SLOW MOTION — 1/3 speed (180 fps camera)", "(w-text_w)/2", "h-th-100", 38) + "," +
            text("a new picture: stock every 3rd camera frame · 144 Hz 4 of 5 · 240 every one", "(w-text_w)/2",
                 "h-th-40", 28, FONT_M))


WIPE_EXPR = "if(lt(abs(X-W*P),4),255,if(lt(X,W*P),A,B))"    # B in from the right behind an 8 px white bar


def section(kind, length, clips, fps):
    scale = 3 if kind == "rt" else 1          # file seconds per on-screen second
    on = length / scale
    n = len(clips)
    g = ";".join(pane(k, m, s, length, kind, fps, WIPE if k else 0, WIPE if k < n - 1 else 0)
                 for k, (m, s) in enumerate(clips))
    cur, t = "p0", on
    for k in range(1, n):
        out = f"x{k}"
        g += f";[{cur}][p{k}]xfade=transition=custom:duration={WIPE}:offset={t}:expr='{WIPE_EXPR}'[{out}]"
        cur, t = out, t + WIPE + on
    g += f";[{cur}]format=yuv420p,{banner(kind, fps)}[v]"
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
    end = card([("Display Settings  >  Frame Rate: Auto", 52, FONT_B),
                ("follows the monitor; the game logic stays at 60", 34, FONT_M)], 3.0, fps)
    jobs = [(f"{i:02d}_{k}", src, section(k, length, clips, fps)) for i, (k, length, clips) in enumerate(SECTIONS)]
    jobs.append(("09_end", None, end))
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
    return final


def small(final):
    """2-pass x264 at the bitrate that lands under SMALL_MB"""
    dur = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", final],
                               capture_output=True, text=True).stdout)
    kbps = int(SMALL_MB * 8192 / dur * 0.97)
    out = final.replace(".mp4", "_small.mp4")
    log = out + ".2pass"
    base = ["ffmpeg", "-v", "error", "-y", "-i", final, "-c:v", "libx264", "-preset", "slower", "-b:v", f"{kbps}k",
            "-pix_fmt", "yuv420p", "-an", "-passlogfile", log]
    run(base + ["-pass", "1", "-f", "mp4", os.devnull])
    run(base + ["-pass", "2", "-movflags", "+faststart", out])
    for f in os.listdir(os.path.dirname(out)):
        if f.startswith(os.path.basename(log)):
            os.remove(os.path.join(os.path.dirname(out), f))
    print(out, f"{os.path.getsize(out) / 1048576:.1f} MB at {kbps} kb/s")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src")
    ap.add_argument("-o", "--outdir", default=os.path.expanduser("~/Videos/showcase"))
    ap.add_argument("--fps", default="60", choices=["60", "180"])
    ap.add_argument("--small", action="store_true", help=f"also a 2-pass copy under {SMALL_MB} MB")
    ap.add_argument("--preview", action="store_true", help="fast encode")
    a = ap.parse_args()
    os.makedirs(a.outdir, exist_ok=True)
    final = render(a.src, a.outdir, int(a.fps), a.preview)
    if a.small:
        small(final)


if __name__ == "__main__":
    main()
