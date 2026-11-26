# hd-textures

AI-upscaled textures, generated **on the user's machine from their own copy** (invariant 9: the pack is
never distributed). The loader replaces each texture by path and keeps its logical size, so UVs and layout
are untouched. Render-only.

## Pipeline — `tools/hd/` (Python; runs where a GPU is: the owner's `lame`, RX 7800 XT 16 GB)
1. **Extract** every image from `lnkdatas.bin` + `bin/data###.bin` (LZSS) and `bmpdata.bin` (LZW) — own
   reader in this repo (formats: openrecet `docs/formats/data-bin.md`, `bmpdata.md`), plus loose files.
2. **Classify**: sprite sheets (point-filtered, colour-keyed), standees/portraits (32-bit alpha), UI,
   backgrounds, mesh textures, font atlas (generated at runtime — not upscaled; a higher-res glyph render is
   a separate loader option).
3. **Prepare alpha**: green key `0xFF00FF00` → alpha (with a key-colour bleed fill so the upscaler doesn't
   smear green into edges); upscale RGB and alpha separately; re-threshold alpha for keyed images.
4. **Upscale**: PyTorch ROCm + spandrel (any model architecture). **Bake-off** per category, owner picks:
   2x-AnimeSharpV4, 4x-IllustrationJaNai DAT2, 4x-UltraSharp, Real-ESRGAN x4plus anime 6B (+ NCNN-Vulkan
   fallback for users without ROCm/CUDA). Scale 4× for sprites/standees, 2× for backgrounds/meshes.
5. **Sprite sheets**: upscale per cell with padding (cells from `formdata.bin` / idx) so neighbours don't
   bleed across cell borders.
6. **Pack**: DDS (DXT5 or A8R8G8B8 by category) with mips for mesh textures → `mod_data\hd\<game path>`;
   manifest with source hashes (regenerate only what changed).

## Gate (S9)
Per-category side-by-side sheets (original | each model) for the owner; in game: no seams, no green halos,
UVs exact (cell-boundary check on Recette's walk cycle), VRAM measured.
