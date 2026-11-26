# wardrobe

Recolour Recette by region, everywhere she appears. UI per the owner's reference: a game-style list —
Hair, Eyes, Skin, Shirt, Top, Tie, Apron, Skirt, Hair bobbles, Boots & belt — each `Original` or a colour
(`#RRGGBB` + swatch), Left/Right steps a curated palette, Button 3 switches palette ↔ fine hue/value edit,
Reset All, Done. Opened from a new pause-menu entry. Live preview on her field sprite. Render-only.

## Facts (loader ENGINE-MAP "Recette's images")
All her art is **truecolour** (24-bit BMP sheet `bmp/chr/chr00.bmp`, 32-bit TGA standees
`bmp/ivent/01recette_00..07.tga`, more to inventory) — no palette to swap. So: region masks + recolour.

## Pipeline
1. **Inventory (S8 RE):** every texture path that shows Recette (log the loader's texture hook across a
   probe corpus; candidates by name: `dot_recet*`, `recetter.tga`, `pause_bg_rete.tga`, `chibi_*`,
   `end_ss*`, title art).
2. **Rules, not pixels (invariant 9):** `mods/wardrobe/regions.json` — per image: seed colours per region in
   LAB with tolerances, optional per-image rectangles (eyes vs. same-coloured bobbles), edge feathering.
   Authored with `tools/wardrobe/` (segments the user's own extracted images, renders an overlay sheet for
   human review). Ships only the rules.
3. **First run:** build soft masks from the user's files → `mod_data\wardrobe\masks\` (consent prompt).
4. **At load:** asset-layer `transform` on those paths: per pixel, per region weight — keep the pixel's
   lightness offset from the region's mean, replace hue/chroma by the target's (LAB), blend by mask
   weight. "Original" for every region = the untouched bytes (byte-identical check).
5. **Live:** a change re-runs the game's loader for the affected slots (`mod.assets.reload`).

Works over HD textures (masks upscaled with the pack, or recolour before upscale — decided in S9).

## Gate (S8)
Contact sheet: every Recette image × 3 palettes + Original — owner eyes. Persists across scenes, restarts,
device reset.
