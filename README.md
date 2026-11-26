# recettear-mods

Mods for *Recettear: An Item Shop's Tale*, built on the
[**Recettear Mod Loader**](../recettear-mod-loader). This repo is a **mod source**: `registry.json` lists
the mods for the loader's launcher (format: the loader's `docs/REGISTRY.md`, same as sotes').

## Status — S0 (design)

Specs only; implementation follows the loader's session plan (`../recettear-mod-loader/docs/SESSIONS.md`).

## The first mods (quality-of-life proof of concept)

| mod | what | spec | session |
|---|---|---|---|
| `unlock-menu` | every title-menu entry (NG+, Survival, Survival Score) regardless of progress | [spec](docs/mods/unlock-menu.md) | S2 |
| `display` | Display Settings page in the game's Options: resolution, display mode, frame rate, aspect, render scale, VSYNC, HD textures, HUD anchor | [spec](docs/mods/display.md) | S3–S5 |
| `free-camera` | an extra camera mode in the shop's Button-4 cycle: orbit, zoom, height | [spec](docs/mods/free-camera.md) | S6 |
| `first-person` | another extra mode: first person with a wide FOV, mouse look, WASD | [spec](docs/mods/first-person.md) | S7 |
| `wardrobe` | recolour Recette by region (hair, eyes, skin, shirt, top, tie, apron, skirt, bobbles, boots & belt) everywhere she appears | [spec](docs/mods/wardrobe.md) | S8 |
| `hd-textures` | AI-upscaled textures, generated on your machine from your copy | [spec](docs/mods/hd-textures.md) | S9 |

## Showcase

(Screenshots land here as each mod ships — S12.)

## Legal

No game files or anything derived from them are in this repo. Mods that need game-derived data (the HD
pack, the wardrobe's region masks) generate it on your machine from your own copy, after asking.
