# recettear-mods — agent entry point

Mods + registry + showcase for `../recettear-mod-loader` (read its CLAUDE.md, HANDOFF, SESSIONS first: the
session plan covers both repos). Specs: `docs/mods/*.md`.

- Never commit game files or anything derived from them (extracted images, masks, HD packs, saves).
  Mods ship code + rules; derived data is generated on the user's machine (`mod_data\`).
- Engine facts: the loader's `docs/ENGINE-MAP.md` → `../openrecet` findings. New facts go to openrecet.
- Terse prose; commit on master in logical units. Public on GitHub since 2026-11-27 (`Francesco149/recettear-mods`,
  MIT); push only when asked. A mod release = version bump + `tools/registry/notes.json` + `tools/registry/registry.py`
  + the tag `<id>-<version>` pushed (the registry's URLs point at it).
- README pictures: `tools/showcase/shots/` (plan.lua → the loader's `tools/win_steam.py … --mods …,shots` →
  `shots.py OUT_DIR` → `docs/img/`).
