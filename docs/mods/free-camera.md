# free-camera

An extra camera mode in the shop's own cycle: Button 4 goes 0 (retail) → 2 (retail low) → **Free** →
**First Person** (if that mod is on) → 0. Render-only.

## Controls (help box on entry, fades after a few seconds; reference screenshot)
| input | action |
|---|---|
| `[` / `]` or right-drag | turn (yaw) |
| PgUp / PgDn, wheel | zoom (orbit distance) |
| Home / End | height |
| Backspace | reset |
| Pad: Skill 1/2 turn, 3/4 zoom, 5 reset | consumed from the game while Free is active |

Movement stays camera-relative (retail: facing = pad angle − camera yaw), so turning the view also turns
WASD/stick directions — the same as retail's own camera.

## Mechanism
- Loader `mod.game.camera.add_mode`: the save-bank mode dword stays 0/2 (invariant 8); the mod's mode is
  loader state, persisted in `rml_mods.cfg`.
- Pose override after retail's pose `0x441c3e` (eye/target), yaw via the yaw target `0x56db060` (so the
  billboard matrix `0x4424e7` and sprite octants follow), pitch from height/distance.
- Limits per room (distance 6–40, height 2–40) so the dioramas' open sides mostly stay out of view.
- Cinematic stage classes (`0x438b4e8` ≠ 0: counter, decor, day end, Move Tables) → hand back to the game's
  camera, restore on return (config `follow_cinematics`).
- Scope: house stages (scene type 0–4). Dungeon/town: later (needs RE of Button 4 there).

## Gate (S6)
`rml det` with Free active and unrotated == vanilla; 4 looked screenshots; counter + customer + day end
with Free on; owner feel check.

## Status (0.1, S6 — 2026-11-27)
Built as specified, with: zoom 6–40 / height 2–40 as the only limits (no per-room clamps; the void shows off the ¾
angle); pad Skill 1/2 turn, 3/4 zoom, 5 reset; `[config]` distance / height / yaw (the last view) / help. Gates:
`rml det` market-buy-display + day2-shop IDENTICAL with Free active and unrotated (counter cinematic hands back and
returns); `tests/lua/camera.lua` 16/16. Turning moves retail's yaw target, so a turned Free changes where Recette walks
(as retail's own camera turns do) — render-only holds unrotated. Owner feel check pending.
0.1 + S7: registers with `order = 10` (first-person uses 20), so the cycle is 0 → 2 → Free → First Person → 0
whichever folder loads first.
