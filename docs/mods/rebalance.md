# Rebalance + QoL (working title) — design draft for feedback

**Status: draft; 1.1 and 1.6 are built (mod 0.1.0), the rest is not.** This is a proposal for a mod for the original PC Recettear (Steam
EN 1.108) running on [recettear-mod-loader](https://github.com/Francesco149/recettear-mod-loader). Tell us
what you would turn on, what you would never touch, and what is missing: open an issue on this repo.
Short version and progress: [mods/rebalance](../../mods/rebalance/README.md).

The mod has three goals:

1. **Explain the game.** Most complaints are about rules the game hides or explains wrongly, not about the
   rules themselves.
2. **Remove friction that isn't a decision.** Lost orders, combo breaks you could not avoid, repeated
   tutorials, companions blocking the view.
3. **Offer balance options, off unless you pick them.** Debt size, a second chance, the loop.

Every item is a separate setting on an in-game Options page. Saves stay loadable by the unmodded game.

## Presets

| Preset | What it turns on |
|---|---|
| **Classic+** | Information and fixes only. No number in the simulation changes. For a first playthrough the way it shipped, minus the guesswork about what the rules are. |
| **Rebalanced** (default) | Classic+ and the friction fixes marked ● below. Debt and economy numbers stay as shipped. |
| **Custom** | Every row on its own. Difficulty options live here. |

In the tables: **C** = on in Classic+, **●** = on in Rebalanced, **○** = off unless you turn it on.
"Build" says how hard it is: **1** = the loader can already read what it needs, **2** = the game code is
mapped and needs a hook, **3** = needs reverse engineering first, may be dropped.

## 1. Show the hidden rules

The most requested change, and the most contested: some players want reputation and budgets on screen,
others say guessing is the point ("like dealing with real people instead of gameable NPCs"). So this is a
dial, not a switch.

| # | Change | Default | Build |
|---|---|---|---|
| 1.1 | **Customer ledger**, a pause-menu page. One row per customer you have met. Level **Hearts**: reputation level (the game has 10, shows a heart for 8 and never lists them) and progress to the next. Level **Full**: also current and maximum budget in pix. Level **Off**. | C: Hearts | 1 |
| 1.2 | **Deal history** in the ledger: per customer, the best and the last price (as % of base) they accepted from you, deals made, items they sold you. Only what you have seen happen, so it is a notebook, not a cheat sheet. | C | 2 |
| 1.3 | **Deal result line.** After each deal, one line: reputation +5 / +2 / +1 / −1 and why (Just price, Near Pin, plain, haggled three times, over budget), merchant XP with the combo bonus. The game already computes all of it and shows only a heart now and then. | C | 2 |
| 1.4 | **Honest tutorial.** Tear's lesson tells you to open at 130 % and haggle. The best outcome is the opposite: a first offer the customer accepts at once gives up to 3× the XP, +5 reputation, and reputation is what grows their wallet. New lines (same voice, text only) say so, and explain Just Bonus, Near Pin, Just Combo and booms when they first happen. | C | 2 |
| 1.5 | **"Over budget" hint** on orders and recommendations: a mark on the price dial once you pass what this customer can pay. Off / After the first failure with this customer / Always. | C: after first failure | 2 |
| 1.6 | **Buying or selling** shown in large on the haggle screen. People pay 130 % for a customer's item by accident. | C | 1 |
| 1.7 | **Time cost before you commit.** The town map says what each destination will cost, and what going home will cost, before you confirm. Dungeons cost 2 periods and a town stop on the same trip adds 1; the game says the first on a tooltip and the second nowhere. | C | 2 |
| 1.8 | **Order reminders.** Morning line when an order is due today; a warning if you leave for a dungeon on a due day. | C | 1 |
| 1.9 | **News and booms visible away from the shop** (Market, guilds, town map). | C | 1 |
| 1.10 | **Numbers on items**: attack / defence / magic on gear, in the description box. | C | 1 |

Open question: should **Full** budgets be the default for a second loop onward (you have "learned" the
customers by then)?

## 2. Selling, customers, orders

| # | Change | Default | Build |
|---|---|---|---|
| 2.1 | **Saying no keeps your combo.** Turning down an order you can't fill, or a customer's offer to sell you something, no longer resets the Just Combo. Haggling badly still does. (This also covers Euria: you can refuse her without losing the chain.) | ● | 2 |
| 2.2 | **Orders are not silently lost.** Today an order disappears the moment you open the shop on its due day, served or not, and vanishes if you don't open. The game contains a "late pickup" visit that this makes unreachable. With this on: the customer comes at your next opening, late, with the game's own late line and no reputation gain. | ● | 2 |
| 2.3 | **Adventurers don't buy downgrades.** They stop picking up gear that is worse than what they wear in the stat their class uses, and stop equipping it. No more pricing a Worn Sword at 500 % to protect your swordsman. Players disagree on how the game decides today (any better stat? defence only? boots that are never worn, a second hat in a free slot), so the first step is to read the real rule out of the game and publish it here. | ● | 3 |
| 2.4 | **Hand gear to an adventurer** at the Adventurers' Guild at the price they would pay in the shop, limited by their budget. Keeps "equip them by selling to them", removes the wait for them to walk in and want that item. | ○ | 3 |
| 2.5 | **Late arrivals catch up.** A customer you unlock mid-game starts at half the average reputation of the ones you already have, instead of zero and a wallet that can't afford anything you stock. | ○ | 2 |
| 2.6 | **Choose what fusion consumes**: the confirm box shows which copy will be used (the game takes the highest +N first) and lets you change it. Items on shelves stay protected, as now. | ● | 3 |
| 2.7 | **Discard an item** from the inventory, with a confirm. | ● | 3 |
| 2.8 | **Window shelf fix**: after the second expansion the new window holds 3 items instead of 4 until you move a counter. Game bug. | C | 3 |
| 2.9 | **Shrink the shop** at the Merchants' Guild, for a fee (announced for the HD Edition). | ○ | 3 |

Left alone on purpose: customer personalities and wallets (the broke little girl is the joke), vending
machines, order bundling, the news booms and crashes.

## 3. Debt, game over, the loop

Opinion is split down the middle here. Many players call the loop the kindest part of the design and lose
on purpose; others want to finish in one run and find the second loop breaks the tension. Nothing in this
section is on by default.

| # | Change | Default | Build |
|---|---|---|---|
| 3.1 | **Debt size**: Relaxed 75 % (615,000 total) / Standard (10k, 30k, 80k, 200k, 500k) / Steep 150 %. Chosen at New Game, shown on the save. | ○ Standard | 2 |
| 3.2 | **Tear's extension.** Miss a payment in weeks 1 to 4 with at least 75 % of it in hand: Tear takes everything you have and adds the shortfall + 25 % to next week. Once per loop. The final payment has no extension. Clearing without using it is marked on the save. | ○ | 2 |
| 3.3 | **Skip what you have seen.** From loop 2, tutorials and story scenes you have already watched skip themselves (hold a button to watch again). | ● | 2 |
| 3.4 | **True Cards for everyone who earned one.** Today a clear gives one card, to the adventurer you took out most, so all cards cost 7+ clears. With this on, every adventurer above a number of runs in that loop gives theirs. | ○ | 3 |
| 3.5 | **No-debt start**: the story's town, events and dungeons without the collection days. | ○ | 3 |

3.3 is in Rebalanced because it changes no outcome. Tell us whether 3.1 should instead be the visible,
first-class choice at New Game.

## 4. Dungeons

| # | Change | Default | Build |
|---|---|---|---|
| 4.1 | **Recette and Tear out of the way** in dungeons: Shown / Faded when they overlap the adventurer or an enemy / Hidden. Display only. | ● Faded | 2 |
| 4.2 | **Drop labels**: item names over drops when you are close, with a mark on items not yet in your encyclopedia (HD Edition). | C | 2 |
| 4.3 | **Boss health bar** always on screen (HD Edition). | C | 1 |
| 4.4 | **Boss retry.** Lose on a boss floor: retry from the start of that floor with the bag as it was, or leave under the normal defeat rule (HD Edition). | ○ | 3 |
| 4.5 | **Dungeon insurance** at the Adventurers' Guild. The HD Edition has only teased the name, so this is our version: pay a fee before leaving (scaled by dungeon depth); if the run ends in defeat you keep 3 more items than your merchant level allows (the game gives 1, then 2 at level 16, 3 at level 50). | ○ | 3 |
| 4.6 | **Bosses drop more**: a second chest on boss floors (HD Edition says "many items", no numbers). | ○ | 3 |
| 4.7 | **Adventurer tuning.** Opinion is split, so nothing is decided: Caillou is "very hard to use" on the wiki and slow to level for English players, and one of the most recommended on 5ch; Nagi was weakened by an official update and people ask for 8-direction attacks; Tielle is helpless up close. We will measure first and publish numbers here before anything ships. | ○ | 3 |
| 4.8 | **Autosave**: a rolling save in its own slot each morning and on reaching the town map; per dungeon floor if the game can resume there (HD Edition; resuming inside a dungeon is not something the original does, so that half may not be possible). | ● morning / town | 2, dungeon 3 |
| 4.9 | **Use a healing item at once** from the bag, without the menu (HD Edition). | ○ | 3 |
| 4.10 | **Kinder completion.** The most repeated complaint in the Japanese thread: the item book from 95 % on is pure luck. Drop and chest odds ×1 / ×2 / ×3 for items you have never found; nothing changes for items you already have, so it is no money engine. | ○ ×1 | 3 |
| 4.11 | **Shorter expeditions**: a dungeon trip costs 1 period instead of 2. For players who say the dungeon is a trap while in debt because two periods of selling earn far more. Disputed: others like that it is a real choice. | ○ | 2 |
| 4.12 | **Save protection**: New Game, New Game + and Survival ask before writing over a slot that holds another run, and never pick an occupied slot by themselves. Lost main saves come up again and again. | C | 2 |

Not planned: more enemy types, new dungeons, hitbox changes, an auto-sell clerk. Feedback on falling-rock
traps, on leaving only every 5 floors and on fusion recipes that need three of a rare item is noted; say
if these matter to you.

## 5. What this mod will not touch

- Free pricing and the per-customer read. "Selling at 1000 once doesn't mean 1000 always works" is the
  most praised thing in the game. Nothing here shows the accepted price before you offer it.
- The loop, the cardboard box, "it was all a dream".
- Booms, crashes, the 3× windfalls, Alouette's wallet, million-pix orders.
- Each adventurer's own moveset; equipping them through the shop.
- Fusion results staying a surprise.
- Survival, Survival Hell, no-dungeon runs: all still possible with every preset.
- The script, voices and localization.

Controls, key config, mouse, resolution and frame rate are the `display` mod's job, not this one's.

## 6. Where this comes from

- **Player feedback, English**: r/Recettear threads, Steam reviews and discussions, GOG forum, TV Tropes
  (its "Scrappy Mechanic" is adventurer gear, 2.3 / 2.4), the Recettear wiki.
- **Player feedback, Japanese**: Steam reviews in Japanese, the atwiki (whose FAQ collects the 2ch threads'
  questions: time slots, wallets, lost orders, the window shelf), blog reviews, 4Gamer, the ニコニコ大百科 article, and the whole 5ch thread "EasyGameStation総合スレ Part15"
  (1000 posts, 2012–2021). That thread's top topics: item-book drop rates (4.10), adventurer gear
  (2.3, 2.4), the dungeon not paying off during the debt (4.11), the loops needed for all cards (3.4).
  It also defends the first-loop debt curve as the best thing in the game, which is why section 3 is off
  by default.
- **HD Edition** (EasyGameStation, announced 2024-12-30, no date as of 2026-11-27): the official account's
  posts. It has shown widescreen, shop layout tools and decorations, shrinking the shop, a guild
  receptionist, a merchant bag, drop labels, instant healing items, an automatic suspend save (resume at
  the start of the floor, not save-anywhere), boss health bar, immediate boss retry, bigger boss drops,
  and the words "adventurer tickets… dungeon insurance?". It has announced **no** balance, difficulty,
  tutorial or hidden-stat changes; those rows are ours.
- **The game's code** as documented in [openrecet](https://github.com/Francesco149/openrecet): budget =
  min + (max − min) × reputation level / 10, checked at ×1.2; reputation +5 / +2 / +1 by how close the
  price is to the customer's target; order slots; the three places time advances.

Three things players report differently from each other, which we will measure in the game before building
on them: whether a dungeon trip and shop periods fit in one day on every route (1.7), how orders are
generated, and exactly when Euria appears.

## 7. Questions for you

1. Ledger default: Hearts or Full? Should Full unlock on loop 2?
2. Is 2.1 (refusing keeps the combo) too generous? Alternative: refusing ends the combo's growth for that
   customer but does not reset it.
3. Debt: is 75 % the right "Relaxed"? Would you use Steep?
4. Tear's extension: once per loop, or once per game?
5. Vending machines on a checkered floor make money meaningless late on. Leave it, or offer a toggle?
6. Adventurer tuning (4.7): who actually needs help?
7. What did we miss?

---

## For modders: what the loader gains

Rule for this project: anything the mod needs from the engine is added to the loader as general API, with
a test, and the mod only holds policy and numbers. Planned surface (names provisional; engine addresses
are in openrecet `docs/findings/`, new facts get recorded there):

| API | What it gives | Used by |
|---|---|---|
| `mod.config` ✅ | Declarative settings (type, default, presets, help) → Options page, load / save, per-save overrides | every row |
| `mod.store` ✅ | Per-save side data keyed to the save slot, following retail's save / load / bank backups / Clear Save Data; the save file itself stays vanilla | 1.2, 3.1, 3.2, 4.5 |
| `mod.ui.native` additions | Pause-menu pages ✅, HUD drawing in the shop ✅ (`on_draw`); toast / result line, confirm box, world-space labels, HUD bars | 1.1–1.10, 4.2, 4.3 |
| `mod.text` | Replace or add dialogue lines and item descriptions by script id; first-time tips | 1.4, 1.10 |
| `mod.game.customers` | `budget(id)` (retail's `0x45ecc0`) ✅, `reputation(id)` / `roster()` ✅, `on_deal{grade, rep, xp, combo}`, `on_combo_break{reason}` (cancellable), `set_closeness`, pick filter `on_pick{item}` | 1.1–1.5, 2.1, 2.3, 2.5 |
| `mod.game.orders` | Slots (10 × 20 bytes at bank + 173560), `on_due`, `on_clear` (cancellable → late pickup) | 1.8, 2.2 |
| `mod.game.time` | `on_advance{site, cost}` over the three sites (shop sale, town return, dungeon exit), `cost(dest)` preview | 1.7 |
| `mod.game.debt` | Schedule override (`0x48d997`), `on_payment{due, gold}` (editable), `on_gameover`, loop count | 3.1, 3.2 |
| `mod.game.events` | Seen flags per script, `on_start` (skippable) | 3.3 |
| `mod.game.dungeon` additions | `on_floor`, `on_defeat{keep}` (editable), `on_boss_kill`, drops list, follower visibility | 4.1–4.6 |
| `mod.game.adventurers` | Stat and move records, equipment compare hook, run counts | 2.3, 2.4, 3.4, 4.7 |
| `mod.game.save.autosave(slot)` | Retail's own save into a reserved slot | 4.8 |
| `mod.game.guild` / `shop` acts | Menu entries at the guilds, discard, shop tier change through retail's re-layout | 2.4, 2.7, 2.9, 4.5 |

Build order: `mod.config` + `mod.store` + pause-menu pages first (they carry Classic+), then
customers / orders / time (the rest of Classic+ and most of Rebalanced), then debt and events, dungeons last.
Each row ships with a determinism check that the mod with the row **off** leaves the simulation
byte-identical to the unmodded game.
