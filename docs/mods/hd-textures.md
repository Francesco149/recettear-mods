# hd-textures

Higher-resolution textures, made **on the user's machine from their own copy** (invariant 9: the pack is
never distributed). The loader replaces each texture by path and keeps its logical size, so UVs and layout
are untouched. Render-only.

## S9 starts with a tradeoff study (owner, 2026-11-26)

Compare, on the same texture set, only options we can **realistically ship** as an optional thing:

| option | what | judge on |
|---|---|---|
| A. user-side preprocessor | a tool the user runs once on their PC over their own assets; portable runtime (NCNN-Vulkan / ONNX-DirectML: any GPU vendor, CPU fallback), licence-compatible models, small download | quality per category, run time on a typical GPU and on CPU, download + disk size, setup friction |
| B. runtime shader | in the loader, at texture load or at sampling: xBRZ, ScaleFX, Anime4K, FSR1-EASU-style | quality, frame time / load-time cost, zero setup |
| C. hybrid | e.g. B by default, A as an opt-in quality pack | combined |

cutestation's RTX 5060 8 GB (the owner's play box; owner 2026-11-26) is the bench for producing comparisons and timing, not the shipping path. Output:
comparison sheets per category + numbers → owner picks. Steps below apply to A (and the alpha/colour-key
handling to B too).

## Preprocessor pipeline (option A) — `tools/hd/`
1. **Extract** every image from `lnkdatas.bin` + `bin/data###.bin` (LZSS) and `bmpdata.bin` (LZW) — own
   reader in this repo (formats: openrecet `docs/formats/data-bin.md`, `bmpdata.md`), plus loose files.
2. **Classify**: sprite sheets (point-filtered, colour-keyed), standees/portraits (32-bit alpha), UI,
   backgrounds, mesh textures, font atlas (generated at runtime — not upscaled; a higher-res glyph render is
   a separate loader option).
3. **Prepare alpha**: green key `0xFF00FF00` → alpha (with a key-colour bleed fill so the upscaler doesn't
   smear green into edges); upscale RGB and alpha separately; re-threshold alpha for keyed images.
4. **Upscale**: candidate models (anime / illustration / texture: AnimeSharp V4, IllustrationJaNai, UltraSharp,
   Real-ESRGAN anime 6B, small compact models), filtered by licence and by running on a shippable runtime;
   scale per category (e.g. 4× sprites/standees, 2× backgrounds/meshes).
5. **Sprite sheets**: upscale per cell with padding (cells from `formdata.bin` / idx) so neighbours don't
   bleed across cell borders.
6. **Pack**: DDS (DXT5 or A8R8G8B8 by category) with mips for mesh textures → `mod_data\hd\<game path>`;
   manifest with source hashes (regenerate only what changed).

## Gate (S9)
The study's sheets + numbers → owner's pick; then for the chosen path: in game: no seams, no green halos,
UVs exact (cell-boundary check on Recette's walk cycle), VRAM measured.
