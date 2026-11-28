# Rebalance + QoL — in development, feedback wanted

A mod for the original PC *Recettear* that explains the rules the game hides, removes friction that isn't a
real decision, and offers balance options that are off unless you pick them. Every change is its own
switch on an in-game Options page. Saves stay loadable by the unmodded game.

**The information rows are in** (version 0.2.0, in this repository; it needs the next mod loader release): the settings
page with presets, the customer ledger with deal history, the deal result line, the trip time on the town map,
order reminders and the buying / selling banner. This page tracks what is being built and why. The full design, with every
row and its default, is in [the design draft](../../docs/mods/rebalance.md).

## Tell us what you think

Open an [issue](https://github.com/Francesco149/recettear-mods/issues) with "rebalance" in the title.
Most useful:

- which rows you would turn on, and which should never be a default;
- anything in the game that annoyed you and isn't listed;
- numbers: is 75 % debt the right "Relaxed"? Who among the adventurers actually needs help?

The open questions we most want answered are at the end of
[the design draft](../../docs/mods/rebalance.md#7-questions-for-you).

## What we heard, and what we are doing about it

Collected from r/Recettear, Steam reviews and discussions (English and Japanese), the GOG forum, the
English and Japanese wikis, Japanese blog reviews, the ニコニコ大百科 article, and the 5ch thread
"EasyGameStation総合スレ Part15" (all 1000 posts). Features the HD Edition has shown on its official
account are marked HD.

| What players said | What the mod does | Default |
|---|---|---|
| "Nothing tells me my reputation with a customer or what they can afford." Others: "guessing is the charm." | A customer ledger page with three levels: off, reputation hearts, or hearts and budgets. A notebook of the prices each customer has accepted from you. | Hearts |
| The tutorial teaches haggling; the game rewards the opposite. Just Bonus, Near Pin and the combo are never explained. | New tutorial lines in Tear's voice; a one-line result after each deal (reputation and XP, and why). | On |
| "I returned from town and lost a time slot." "I went to the dungeon in the morning and three slots passed." | The town map says what each trip will cost before you confirm. | On |
| Orders vanish if you don't serve them on the day. Orders clash with dungeon days. | Morning reminder; the customer comes back late instead of the order disappearing. | On |
| Refusing an order or an unwanted sell offer breaks the combo. Euria the "combo breaker". | Saying no keeps your combo. Haggling badly still breaks it. | On |
| Adventurers buy and wear worse gear; getting good gear onto them is luck. (The top complaint on TV Tropes and one of the top two on 5ch.) | They stop buying downgrades. Optional: hand gear over at the guild, at their price and within their budget. | On / optional |
| The item book from 95 % on is pure luck. (The most repeated topic on 5ch.) | Optional better odds for items you have never found. | Off |
| "The dungeon is a trap while you're in debt." Others disagree. | Optional: a dungeon trip costs 1 time slot instead of 2. | Off |
| The debt is too steep / the debt curve is the best part of the game. | Optional debt size (75 % / 100 % / 150 %) and a one-time extension from Tear. | Off |
| Loops repeat the same tutorials and scenes. All True Cards need 7+ clears. | Seen scenes skip themselves from loop 2. Optional: every adventurer who earned a card gives it. | On / off |
| Recette and Tear get in the way in dungeons. | They fade when they overlap the action, or hide. | Fade |
| New Game or Survival wrote over my main save. | The game asks first; a rolling autosave in its own slot (HD). | On |
| Bosses kill you before you understand them; defeat loses nearly everything. | Optional boss retry (HD) and dungeon insurance (HD teased the name; the rules are ours). Boss health bar (HD). | Off / on |
| I can't tell what a drop is. | Names over drops, with a mark on items not yet in your book (HD). | On |

## What stays as it is

Free pricing and reading each customer; the loop and the cardboard box; booms and crashes; each
adventurer's moveset and equipping them through the shop; fusion surprises; Survival; the script and
voices. Nothing in the mod shows you the accepted price before you make an offer.

## Progress

| Step | State |
|---|---|
| Design draft and feedback round | open |
| Settings page with presets, per-save mod data, pause-menu pages (loader) | done |
| Classic+ : customer ledger (pause menu → Customers), buying / selling banner | done (0.1.0) |
| Classic+ : deal result line, deal history, trip time on the town map, order reminders | done (0.2.0) |
| Classic+ : honest tutorial lines, over-budget hint, news away from the shop, numbers on items, save protection | next |
| Rebalanced: combo, late orders, gear, scene skipping, companions | not started |
| Options: debt, extension, completion odds, expeditions | not started |
| Dungeon features from the HD Edition | not started |

Each step is published here as it lands, with the rows it adds.

## What 0.2.0 does

- **Options → Rebalance + QoL** (title and pause; Up from the top row, then Right): a Preset row (Rebalanced /
  Classic+ / Off) and one row per change.
- **Customer Ledger**: a new "Customers" entry in the pause menu. One row per customer you have dealt with:
  reputation level 0–10 and the points toward the next level (a deal gives +5, +2 or +1 by how close your price was to
  what they had in mind; a refusal or a third offer costs 1). Set the row to "Rep. + Budget" to also see what
  each customer can pay now and at level 10.
- **Deal History**: the ledger's line under each customer notes what you have seen them accept: the best and the
  last price they paid you (as % of the base price) and the lowest they sold to you for. Kept with the save.
- **Deal Result Line**: after each offer, a headline above the shop ("Just price!", "Near pin!", "Deal", "They
  haggle", "No deal", "More than they can pay") over a row of what it did, each in its own colour: "Reputation +2",
  "EXP +17", "Combo x1", "Combo x3 lost", "Out of patience". Everything on it is what the game computed; nothing is
  shown before you make the offer.
- **Trip Time on the Map**: at the top of the town map, what the place under the cursor really costs: "Free to enter. The
  walk home will then take 1 period", "A dungeon run from here takes 3 periods. 2 for the run, 1 for the stop you made".
  With an order due today, its line shows there too.
- **Order Reminders**: in the morning and when you load a save: "Order due today: Louie, 2 scarves" (also "due
  tomorrow").
- **Buy / Sell Banner**: "You are buying" or "You are selling" above the price dial, for shelf sales, requests,
  order pickups and customers selling to you.

One thing we learned while measuring: the combo counts deals accepted on your **first offer**, whatever the price
(it is not only for "Just" prices). Any customer who haggles back or leaves without a deal ends it.

Nothing in 0.2.0 changes the simulation.
