# first-person

A further camera mode in the Button-4 cycle: through Recette's eyes, with a much wider field of view than
the owner's reference capture (that one is ~60–70° horizontal; default here 100°, range 70–130).

## Controls (help box per reference screenshot)
| input | action |
|---|---|
| Mouse | look around (cursor captured; Esc / alt-tab releases) |
| W A S D | walk (mapped to pad directions relative to the view) |
| Left click | interact (the game's confirm) |
| Right click / Tab | menu (the game's cancel/menu) |
| Backspace | reset view |
| Menus | WASD navigate, click = OK, right-click = back |
| Pad | right stick look (if present), rest unchanged |

## Mechanism
- Eye = Recette's position (`0x56da1d8..e0`) + head height (RE in S7: sprite cell 128 px, y-origin 114,
  scale 100 → world units; record in openrecet); target = eye + (yaw, pitch); yaw also written to the yaw
  target `0x56db060` so facing, interaction reach (facing checks like Tear's `0x438be7c`) and billboards
  follow the view.
- Hide her own billboard + shadow (walker `0x4552d0` / shadow `0x45aa36` skip for actor 0) — render-only.
- Projection: horizontal FOV → vertical for the aspect; near 0.1 with the loader's D24S8 depth (retail D16
  + near 1.0 would clip and z-fight).
- Input: pad-mask injection per tick (deterministic in lockstep); mouse via the loader's WndProc layer.
- Same scope / cinematic hand-back rules as free-camera.

## Gate (S7)
Talk to Tear, open the counter menu, place an item on a table, serve a customer, leave by the door — all in
first person; FOV slider live; owner feel check on cutestation.

## Status (0.1, S7 — 2026-11-27)
Built as specified, with:
- Controls: mouse look (raw input, captured only in free roam while the window has the focus; menus, pause,
  cinematics and alt-tab release it), W A S D, left click = confirm, right click = menu in free roam / back in menus,
  Tab = menu, Backspace levels the view, pad Skill 1/2 turn, 3/4 look up / down, 5 level. Retail's own bindings of
  W / A / S / D are swallowed while held (default: W = button E = the pause menu).
- Standing still, Recette faces where you look (her facing `0x56db05c`), so the click reaches what is in front of the
  reticle; walking uses retail's own camera-relative movement with the camera's yaw snapped to the view.
- Eye height 2.6 (her sprite top is 3.42); FOV 100° horizontal (70–130), near 0.1 (0.3 without the loader's D24);
  ~12-frame ease in from the game camera; reticle + help box in free roam only.
- A "First Person" page in the title + pause Options: field of view, mouse sensitivity, invert Y, eye height, help —
  all live.
- Gates: `tests/lua/first_person.lua` 25/25 (Tear by click, her menu + right click back, W walk, Tab pause, the door
  → leaving the shop, FOV / near in retail's projection, hide, leave), `tests/lua/fp_display.lua` 9/9 (a table's
  display menu, the counter menu). Customers are served in retail's own cinematic: the camera hands back there.
- Not render-only (the yaw and the idle facing are game state), as with a turned free camera.
- No right-stick look (retail reads only the left stick; the loader exposes no axes). Owner feel check pending.
