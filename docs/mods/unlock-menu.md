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

## Status (2026-11-26, v0.2) — owner decision: "unlock the main menu regardless of saves"
- **Rows**: all 8 always (5 4 6 1 7 8 2 3), LOAD GAME included with no save (its page lists NO-DATA slots; the
  confirm buzzes on them, retail). Post-hook on both calls of the build `0x49a43d`; retail's 8-row layout
  (`0x5d1bb4` = 27, `0x5d1bb8` = −36); cursor on LOAD when a save exists (retail), else on NEW GAME.
- **NG+ / Survival from any slot**: the picker lists all 100 slots. Retail's confirm (inline in title logic
  `0x49a59e`) wants the slot occupied (+8 > 0); Survival also GAME_MODE 3 (+0x2dd64) and the clear-item byte
  `0x96432f4[bank]`. On a tick with A pressed in the picker, a call-site hook on the title-logic call (`0x453bc3`)
  sets those fields of the chosen slot before the call and puts them back after it (`0x490259` has copied the slot
  into the work bank by then). The arena (= save.dat image) is never left changed.
- **Empty slot = fresh start**: every unused slot holds retail's blank bank (`0x49001c`, written at boot for any slot
  without a valid magic/checksum), so NG+ / Survival from it = a new game run through retail's NG+ / Survival
  transforms (`0x49d55c`, `0x4864fd`).
- Verified (wine): `@fresh` → 8 rows; NG+ from empty slot 001 → NG+ opening (script "So! I have an item shop!"),
  1000 pix, work-bank mode 1; Survival (Normal) from empty slot 001 → "Welcome, everyone, to Normal Survival mode!",
  mode 2; Survival from save 64d43650's non-cleared slot 002 → mode 2; in all three the source slot's arena fields
  read back unchanged.

## Config
`[config.mode]` = `"all"` (default) | `"vanilla"`. (v0.1's `any_save_ng_plus` is gone: any slot is always offered.)

## Gate (S2)
`@fresh` (no save.dat): 8 rows, screenshot. Each new entry starts (NG+ from a day-2 save → day 1 with carried
items; Survival → survival day 1). Save, then load in vanilla. `rml det` not applicable (not render-only).
