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

## Config
`[config.mode]` = `"all"` (default) | `"vanilla"`; `[config.any_save_ng_plus]` bool (a).

## Gate (S2)
`@fresh` (no save.dat): 8 rows, screenshot. Each new entry starts (NG+ from a day-2 save → day 1 with carried
items; Survival → survival day 1). Save, then load in vanilla. `rml det` not applicable (not render-only).
