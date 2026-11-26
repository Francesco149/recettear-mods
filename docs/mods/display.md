# display — Display Settings

A "◀ Display Settings ▶" page in the game's own Options (title and pause), drawn with the game's panel and
font (reference: owner screenshot, 2026-11-26). Render-only. The mechanisms are loader services (loader
DESIGN.md "Graphics layer"); this mod is the settings + page.

| row | values | default | applies |
|---|---|---|---|
| Resolution | desktop modes + window sizes; `Native` = monitor | monitor | on confirm (device reset) |
| Display Mode | Windowed / Borderless / Fullscreen | Borderless | on confirm |
| Frame Rate | 60 · Auto (refresh, e.g. 165) | 60 → Auto after S10 | live |
| Aspect Ratio | 4:3 (pillarbox) · 16:9 · 16:10 · 21:9 · Auto | Auto | live |
| Render Scale | 1× · 1.5× · 2× · 3× · 4× | 1× (2× if GPU allows) | on confirm |
| VSYNC | ON / OFF | ON | live |
| HD Textures | ON / OFF (greyed when no pack generated) | ON if pack | reload |
| Backgrounds (widescreen) | Auto (per picture) · Pillarbox · Zoom + Crop · Stretch → `fullbg=auto\|pillar\|cover\|stretch` | Auto | live |
| HUD Anchor | 0–100 % (0 = HUD in the 4:3 centre, 100 = screen edges) | 100 % | live |
| Sprite Filter | Point (retail) / Smooth | Point | live |

Persists in `rml_mods.cfg` (`display.*`); never in recet.ini (so the vanilla launcher's settings survive).
Gate: S5 (layout vs reference; controller-only nav; each row applies), plus S3/S4 gates for the mechanisms.

## Status (0.1, S5 — 2026-11-26)

Built: `mods/display` on `mod.ui.native` + `mod.gfx.apply`. Display Mode / Resolution / Render Scale are **staged**
(marked `*`) and applied together with Button 1 (one device Reset); Aspect / Backgrounds / HUD Anchor / VSYNC apply
as you step them; every change is saved under `display.*` in `rml_mods.cfg` and applied at start (one Reset right
after boot). Not yet: Frame Rate (S10), HD Textures (S9), Sprite Filter — shown greyed; 1.5× render scale; a
"keep these settings?" revert timer. Open it: Options → Up (header) → Right.
