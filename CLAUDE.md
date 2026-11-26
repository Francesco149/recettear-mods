# recettear-mods — agent entry point

Mods + registry + showcase for `../recettear-mod-loader` (read its CLAUDE.md, HANDOFF, SESSIONS first: the
session plan covers both repos). Specs: `docs/mods/*.md`.

- Never commit game files or anything derived from them (extracted images, masks, HD packs, saves).
  Mods ship code + rules; derived data is generated on the user's machine (`mod_data\`).
- Engine facts: the loader's `docs/ENGINE-MAP.md` → `../openrecet` findings. New facts go to openrecet.
- Terse prose; commit on master in logical units. **No GitHub repo / push until the PoC mods work with showcase
  screenshots** (owner 2026-11-26), then only when asked.
