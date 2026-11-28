-- rebalance — Rebalance + QoL (design: docs/mods/rebalance.md).  The mod holds policy and numbers; everything it
-- needs from the engine is loader API (mod.config pages + presets, mod.store, pause-menu pages, mod.game.*).
-- Built so far: 1.1 customer ledger, 1.2 deal history, 1.3 deal result line, 1.6 buying / selling banner,
-- 1.7 time cost on the town map, 1.8 order reminders.
local ui, cfg, game, store = mod.ui.native, mod.config, mod.game, mod.store
if not (ui and ui.toast and cfg.page and game.customers and game.customers.on_deal and game.orders and game.time) then
  mod.log("needs loader API 1.13") return
end
local R = { cfg = cfg }
_G.rebalance = R

cfg.page{ title = "Rebalance + QoL", width = 400 }

-- ── 1.1 Customer ledger: one row per customer you have dealt with ──
-- Reputation level = points / 10 (0..10; the game shows a heart now and then and never lists them); a deal gives
-- +5 / +2 / +1 points by how close your price was to theirs.  "Rep. + Budget" adds what they can pay now and at most.
local function commas(n)
  local s = tostring(math.floor(n))
  local k
  repeat s, k = s:gsub("^(%-?%d+)(%d%d%d)", "%1,%2") until k == 0
  return s
end
function R.ledger_rows()
  local full = cfg.get("ledger") == "full"
  local rows = {}
  for _, c in ipairs(game.customers.roster()) do
    if c.points > 0 or c.hearts > 0 then
      local rep = c.level >= 10 and "Lv 10 (max)" or ("Lv %d  %d/10"):format(c.level, c.points % 10)
      local help = full and ("Pays up to %s pix now, %s at Lv 10"):format(commas(c.budget), commas(c.budget_hi))
               or (c.level >= 10 and "As loyal as they get" or ("%d more point%s to Lv %d"):format(c.to_next, c.to_next == 1 and "" or "s", c.level + 1))
      local h = R.history_line(c.id)
      rows[#rows + 1] = { label = c.name, customer = c.id, value = function() return rep end,
                          help = h and (h .. "  |  " .. help) or help }
    end
  end
  table.sort(rows, function(a, b) return a.customer < b.customer end)
  if #rows == 0 then
    rows[1] = { label = "No customers yet", center = true, enabled = function() return false end,
                help = "Sell something first" }
  end
  return rows
end
local ledger
local function ledger_sync()          -- the page exists only while the row is on
  local on = cfg.get("ledger") ~= "off"
  if on and not ledger then
    ledger = ui.page("pause", "Customers", {})
    ledger.width = 400
    ledger.on_open = function(p) p.rows = R.ledger_rows() end
  end
  if ledger then ledger.hidden = not on end
end
ledger_sync()

-- ── 1.2 Deal history + 1.3 deal result line: the loader's on_deal event (one per price decision) ──
-- History = a notebook of what you have seen happen, kept with the save (mod.store): per customer, deals where they
-- paid you (count, best and last price as % of base) and deals where you paid them (count, lowest %).
local function pct(e) return e.base and e.base > 0 and math.floor(e.price * 100 / e.base + 0.5) or 0 end
function R.history(id) return (store.get("deals") or {})["c" .. id] end
function R.history_line(id)
  if not cfg.get("deal_history") then return nil end
  local h = R.history(id)
  if not h then return nil end
  local t = {}
  if (h.sold or 0) > 0 then t[#t + 1] = ("Paid you up to %d%%, last %d%% (%d)"):format(h.best, h.last, h.sold) end
  if (h.bought or 0) > 0 then t[#t + 1] = ("sold to you from %d%% (%d)"):format(h.low, h.bought) end
  return #t > 0 and table.concat(t, ", ") or nil
end
local function remember(e)
  if e.outcome ~= "accept" or e.scripted or not store.active() then return end
  local all = store.get("deals") or {}
  local h = all["c" .. e.customer] or {}
  local p = pct(e)
  if e.kind == 0 then
    h.bought = (h.bought or 0) + 1
    h.low = math.min(h.low or p, p)
  else
    h.sold = (h.sold or 0) + 1
    h.best = math.max(h.best or p, p)
    h.last = p
  end
  all["c" .. e.customer] = h
  store.set("deals", all)
end
-- The line: what the game computed and shows only as a heart now and then.
local function signed(n) return (n >= 0 and "+" or "-") .. math.abs(n) end
function R.deal_line(e)
  local t = {}
  if e.outcome == "accept" then
    t[1] = e.grade == 1 and "Just price!" or e.grade == 2 and "Near pin!" or "Deal"
    if not e.scripted then
      t[#t + 1] = "Reputation " .. signed(e.rep) .. (e.third_round and " (third offer -1)" or "") .. (e.level_up and ", level up" or "")
    end
    if e.xp then
      t[#t + 1] = "EXP +" .. e.xp.total .. (e.xp.combo and (" (combo " .. e.combo .. ": +" .. e.xp.combo .. ")") or "")
    end
  else
    t[1] = e.outcome == "walk_out" and "No deal" or e.outcome == "over_budget" and "More than they can pay" or "They haggle"
    if e.rep ~= 0 then t[#t + 1] = "Reputation " .. signed(e.rep) .. (e.third_round and " (third offer)" or "") end
    if (e.combo_lost or 0) > 0 then t[#t + 1] = "combo " .. e.combo_lost .. " lost" end
    if e.leaving and e.outcome ~= "walk_out" then t[#t + 1] = "out of patience" end
  end
  return table.concat(t, "  |  ")
end
local LINE = {
  good = { face = "Comic Sans MS", px = 16, weight = 900, top = 0xffffff, bottom = 0xffe08a, edge_rgb = 0x2a0c00, edge = 2, shadow = 2, fat = 1 },
  bad  = { face = "Comic Sans MS", px = 16, weight = 900, top = 0xffffff, bottom = 0xb9c6ff, edge_rgb = 0x14151c, edge = 2, shadow = 2, fat = 1 },
}
game.customers.on_deal(function(e)
  R.last_deal = e
  remember(e)
  if cfg.get("deal_line") then
    R.last_line = R.deal_line(e)
    ui.toast(R.last_line, { id = "rebalance.deal", y = 96, ticks = 240, style = e.outcome == "accept" and LINE.good or LINE.bad })
  end
end)

-- ── 1.8 Order reminders: each morning (and when a save is loaded), what is due today and tomorrow ──
-- An order is gone the moment the shop opens on its day, served or not, so the day it is due is the day to know.
local function order_text(o) return ("%s, %d %s"):format(o.name or "?", o.qty or 0, o.kind_name or "?") end
function R.reminders(orders)
  local lines = {}
  for _, o in ipairs(orders or game.orders.list()) do
    if o.days < 0 then lines[#lines + 1] = "Order overdue: " .. order_text(o)
    elseif o.days == 0 then lines[#lines + 1] = "Order due today: " .. order_text(o)
    elseif o.days == 1 then lines[#lines + 1] = "Order due tomorrow: " .. order_text(o) end
  end
  return lines
end
local REMIND = { face = "Comic Sans MS", px = 16, weight = 900, top = 0xffffff, bottom = 0xffc0d8, edge_rgb = 0x2a0018, edge = 2, shadow = 2, fat = 1 }
local function remind(orders)
  if not cfg.get("order_reminders") then return end
  R.last_reminders = R.reminders(orders)
  for i, l in ipairs(R.last_reminders) do ui.toast(l, { id = "rebalance.order" .. i, y = 132, ticks = 480, style = REMIND }) end
end
game.orders.on_morning(remind)
store.on_load(function(reason) if reason == "load" then remind() end end)

-- ── 1.7 Time cost on the town map, before you commit ──
-- The game's own box says "This action will not take any time" for every place, which is true of the door and not of
-- the trip: a stop makes the walk home take a period, and a dungeon run takes two plus the stop you made before it.
local function ends_day(n) return (game.time.period() or 0) + n >= 4 and " and ends the day" or "" end
function R.trip_line()
  if not cfg.get("time_cost") or not game.time.on_map() then return nil end
  local d = game.time.cursor()
  if not d or d == game.time.HOME or game.time.dest(d) == 0 then return nil end   -- the box is right about the walk home
  local c = game.time.cost(d)
  if c.dungeon == 3 then
    return "A dungeon run from here takes 3 periods: 2, and 1 for the stop you made" .. ends_day(3)
  elseif c.dungeon then
    return "A dungeon run takes 2 periods" .. ends_day(2) .. ". A stop on the way back takes 1 more"
  elseif c.later == 1 then
    return "Free to enter. The walk home will then take 1 period" .. ends_day(1)
  end
  return "No extra time: the walk home already takes 1 period"
end
local TRIP = { face = "Comic Sans MS", px = 15, weight = 900, top = 0xffffff, bottom = 0xd8ecff, edge_rgb = 0x101828, edge = 2, shadow = 2, fat = 1 }
ui.on_draw(function()
  local line = R.trip_line()
  if not line then return end
  local due = cfg.get("order_reminders") and game.orders.due(0)[1]
  if due then
    local l = ui.label((due.days < 0 and "Order overdue: " or "Order due today: ") .. (due.name or "?") .. ", " .. due.qty .. " " .. (due.kind_name or "?"), TRIP)
    if l then ui.draw_label(l, 320, 432) end
  end
  local l = ui.label(line, TRIP)
  if l then ui.draw_label(l, 320, 456) else ui.text(320, 448, line, 0xff7f7f7f, 0.8, "c") end
end, "map")

-- ── 1.6 Buying or selling, while the price dial is up ──
-- Every customer machine shows the dial in state 6 and its confirmation (Okay! / Start Again) in 15.  Kind 0 = the customer sells to you (you pay); 1 = a request
-- ("something to …"), 2 = an item off your shelves, 4 / 5 = an order picked up: you sell.  3 (placing an order) has
-- no price.
local BANNER = {
  [0] = { "You are buying",  { face = "Comic Sans MS", px = 22, weight = 900, top = 0xffe9a0, bottom = 0xff8c1a, edge_rgb = 0x2a0c00, edge = 2, shadow = 2, fat = 1 } },
  sell  = { "You are selling", { face = "Comic Sans MS", px = 22, weight = 900, top = 0xe6ffd0, bottom = 0x4fc23a, edge_rgb = 0x061c06, edge = 2, shadow = 2, fat = 1 } },
}
BANNER[1], BANNER[2], BANNER[4], BANNER[5] = BANNER.sell, BANNER.sell, BANNER.sell, BANNER.sell
function R.banner()
  if not cfg.get("deal_banner") then return nil end
  local c = game.customers.active() and game.customers.current()
  if not c or (c.state ~= 6 and c.state ~= 15) then return nil end   -- 6 the dial, 15 its Okay! / Start Again box
  return BANNER[c.kind]
end
-- between the item's "Base Price" plate (ends y 196) and the dial's bubble (text from y 250), on the plate's centre
ui.on_draw(function()
  local b = R.banner()
  if not b then return end
  local l = ui.label(b[1], b[2])
  if l then ui.draw_label(l, 304, 216) else ui.text(304, 206, b[1], 0xff7f7f7f, 1, "c") end
end)

cfg.on_change(function(key) if key == "ledger" then ledger_sync() end end)
