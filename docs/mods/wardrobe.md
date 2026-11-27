# wardrobe

Recolour Recette by region, everywhere she appears. A game-style page — Preset, then Hair, Eyes, Skin, Shirt, Top,
Tie, Apron, Skirt, Hair bobbles, Boots & belt, each `Original` or a colour (`#RRGGBB` + swatch), Left/Right steps a
curated palette, Button 3 switches palette → hue → lightness → saturation edit, Reset All — in the title and pause
Options (Up from the top row, Left/Right to "Wardrobe"). Live preview: her field sprite (front + back) beside the page,
recoloured as you step. Render-only.

## As built (S8, 0.1.0)
- **Pictures** (inventory: loader ENGINE-MAP "Recette's images"): the field sheet `bmp/chr/chr00.bmp` (resident; reloaded
  live), the 8 standees `bmp/ivent/01recette_0?.tga`, the kneeling chibi `bmp/ivent/dot_recet0?.tga`, the pause art
  `bmp/pause_bg_rete.tga`. Not covered: `bg_recettear.bmp` (Recette over a painted town: the background shares her colours,
  rects can't separate them), the ending screenshots `end_ss*`, the face icons in `hpmp_base.tga`.
- **Rules, not pixels** (`regions.txt`, grammar in the loader's `core/recolor.h`): global LAB seeds per region; per image
  `only` / `not` / `none` rects (bobbles vs the red apron, eyes vs hair, the gold fittings vs the shirt, Tear and the shop
  sign out); the field sheet is ~90-colour pixel art, so its block names each palette colour (tight seeds).
- **No mask files**: segmentation runs in C at load (memoised per colour: the field sheet ≈ 15 ms under wine), so nothing
  derived is ever written to disk — the first-run mask step and its consent prompt aren't needed.
- **Recolour**: per region, LAB: lightness mapped piecewise so the region's mean lands on the target's (shading kept),
  chroma rotated + scaled from the region's mean hue to the target's; soft weights at region edges. "Original" for every
  region = D3DX gets the untouched file bytes (texture hash = vanilla's).
- Presets in `palettes.txt` (Midnight, Sakura, Forest); editing a region from a preset copies it into Custom.
- Settings in `rml_mods.cfg` (`wardrobe.preset`, `wardrobe.<region>` = `#rrggbb` / empty).
- Authoring: `tools/wardrobe/wardrobe.py --src <your extracted data> overlay | sheet | lab` (the loader's kernel via
  ctypes: `make -C ../recettear-mod-loader/tools/librecolor`).

## Deviations from the S0 spec
- Opened from the Options pages, not a new pause-menu entry (pause-menu entries are still unbuilt).
- No first-run mask files / consent prompt (masks are computed in memory at load from the rules).
