# Showcase media

Pipelines from the owner's own recordings to showcase videos / pictures (S12 README showcase). Source recordings stay
outside the repo (`~/Videos/`); outputs go to `~/Videos/showcase/` until the showcase picks them.

- `hirefresh.py SRC.MOV [--fps 60|180|both]` — the high-refresh video from a 180 fps camera recording of a 144 Hz monitor (stock 60 → Auto 144 → 240 vsync off). Every comparison is a full-screen wipe: title → real time stock → 144 → 240 → slow motion stock → 144 → 240 on one timeline (the same turn in all three recordings, aligned by motion-energy cross-correlation) → end card.
