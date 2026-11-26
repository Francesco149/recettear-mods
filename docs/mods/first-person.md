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
