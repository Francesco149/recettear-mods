# unlock-menu

Goal: the full title menu from the first boot — NEW GAME, NEW GAME +, SURVIVAL MODE, LOAD GAME, ITEM
ENCYCLOPEDIA, SURVIVAL SCORE, OPTIONS, EXIT — whatever the saves hold. Not render-only (changes what the
player can start), but writes nothing retail couldn't.

## Mechanism (engine: loader `docs/ENGINE-MAP.md` "Title menu")
- Tier-2 hook on the unlock scan `0x49a324`: return `3` (bit0 = cleared, bit1 = clear item) → the build
  `0x49a43d` lists codes 5 4 6 1 7 8 2 3 (8 rows — the table's max; row spacing handled by retail).
- SURVIVAL SCORE (code 8) shows on bit0 already; the records page reads the header records (zeros = fine).
- **NG+ / Survival need a source bank**: retail's picker filter `0x49b4f4` keeps only banks with GAME_MODE 3
  + the clear item. Per the owner's decision (DESIGN.md open decisions):
  - (a) widen the filter to every occupied bank → NG+/Survival carry that save over;
  - (b) fresh start with no source bank (needs RE of what NG+ `0x4864fd` copies — S2 task);
  - default proposal: (a), plus (b) when no save exists.
- Never set `word 0x56e5788` or stamp banks: the unlock is computed every boot, so removing the mod
  restores the vanilla menu.

## Status (S2, 2026-11-26) — implemented, `mods/unlock-menu`
- Call-site hook (not a function hook) on the build's one call of the scan (`0x49a46a`); NG+ picker widened
  on both filter call sites (`0x49b0b1`, `0x49b33c`) when the cursor row is code 4.
- Decision taken for now: (a) for **NG+ only**. Retail's Survival confirm re-checks GAME_MODE 3 + the clear
  item on the source bank, so Survival keeps retail's rule (no save edits — invariant 8). (b) is open (owner).
- Gate results (wine): `@fresh` → 7 rows (5 4 6 7 8 2 3: LOAD hidden with no save, as retail); save 64d43650
  → 8 rows; NG+ from a Day-1 non-cleared bank → NG+ opening (game mode 1); saved to slot 001 → loads with no
  mod (game mode 1, Day 2); Survival from the cleared Endless save c062daff → game mode 2; without the mod the
  title is vanilla again (0 1 7 2 3).

## Config
`[config.mode]` = `"all"` (default) | `"vanilla"`; `[config.any_save_ng_plus]` bool (a), default true.

## Gate (S2)
`@fresh` (no save.dat): 8 rows, screenshot. Each new entry starts (NG+ from a day-2 save → day 1 with carried
items; Survival → survival day 1). Save, then load in vanilla. `rml det` not applicable (not render-only).
