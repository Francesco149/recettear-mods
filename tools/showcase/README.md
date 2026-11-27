# Showcase media

Pipelines from the owner's own recordings to showcase videos / pictures (S12 README showcase). Source recordings stay
outside the repo (`~/Videos/`); outputs go to `~/Videos/showcase/` until the showcase picks them.

- `hirefresh.py SRC.MOV [--fps 60|180|both]` — the high-refresh video from a 180 fps camera recording of a 144 Hz monitor (stock 60 →
  Auto 144 → 240 vsync off). Title → side by side (the 4:3 middle, letterboxed) stock | 144 (real time, slow motion) → 144 | 240 (real time, slow
  motion) → full-screen wipes stock → 144 → 240 → end card. Two cuts: `hirefresh_60.mp4` (the real-time parts blend
  the 3 camera frames behind each video frame: extra frames read as smooth blur; plays anywhere) and
  `hirefresh_180.mp4` (every camera frame; high-refresh screens). Clip windows (`CLIPS`, file seconds) are matched by
  motion-energy cross-correlation; `--preview` = fast encode.
