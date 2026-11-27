# Showcase media

Pipelines from the owner's own recordings to showcase videos / pictures (S12 README showcase). Source recordings stay
outside the repo (`~/Videos/`); outputs go to `~/Videos/showcase/` until the showcase picks them.


- `hirefresh.py SRC.MOV [--small]` — the high-refresh video from a 180 fps camera recording of a 144 Hz monitor (stock 60 → Auto 144 → 240 vsync off; the same mouse routine in each). Two three-way wipe sections, real time then slow motion: each clip plays the same stretch of the routine pause to pause (aligned by picture matching), wipes run in the pauses with both sides playing, behind a white divider. `--small` = a 2-pass copy under 19 MB (`hirefresh_60_small.mp4`).
