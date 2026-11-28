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
  if R.pages_sync then R.pages_sync() end
end

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
-- The result: what the game computed and shows only as a heart now and then.  A headline (what happened) over a
-- row of numbers, each in its own colour: reputation pink, EXP yellow like the game's own EXP rows, combo orange.
local function signed(n) return (n >= 0 and "+" or "-") .. math.abs(n) end
local function st(px, top, bottom, edge)
  return { face = "Comic Sans MS", px = px, weight = 900, top = top, bottom = bottom, edge_rgb = edge, edge = 2, shadow = 2, fat = 1 }
end
local DEAL = {
  just = st(24, 0xfff6a0, 0xff9a1a, 0x2a0c00), near = st(22, 0xffffff, 0xffd060, 0x2a0c00), deal = st(20, 0xffffff, 0xcfe8b0, 0x0c1c06),
  bad  = st(20, 0xffffff, 0xb9c6ff, 0x14151c),
  rep  = st(15, 0xffe6f0, 0xff8fb8, 0x2a0018), rep_down = st(15, 0xe6e9ff, 0x8f9bd8, 0x10142a),
  xp   = st(15, 0xfffbd0, 0xffd21a, 0x2a1a00), combo = st(15, 0xffe9c0, 0xff8c1a, 0x2a0c00), note = st(15, 0xffffff, 0xc4c9d8, 0x14151c),
}
-- → headline {text, style}, details { {text, style}, … }
function R.deal_parts(e)
  local head, d = nil, {}
  local function rep()
    if e.rep ~= 0 or e.outcome == "accept" then
      d[#d + 1] = { "Reputation " .. signed(e.rep) .. (e.third_round and " (third offer)" or ""), e.rep < 0 and DEAL.rep_down or DEAL.rep }
    end
  end
  if e.outcome == "accept" then
    head = e.grade == 1 and { "Just price!", DEAL.just } or e.grade == 2 and { "Near pin!", DEAL.near } or { "Deal", DEAL.deal }
    if not e.scripted then rep() end
    if e.level_up then d[#d + 1] = { "Level up", DEAL.rep } end
    if e.xp then
      d[#d + 1] = { "EXP +" .. e.xp.total, DEAL.xp }
      if e.xp.combo then d[#d + 1] = { "Combo x" .. e.combo, DEAL.combo } end
    end
  else
    head = { e.outcome == "walk_out" and "No deal" or e.outcome == "over_budget" and "More than they can pay" or "They haggle", DEAL.bad }
    rep()
    if (e.combo_lost or 0) > 0 then d[#d + 1] = { "Combo x" .. e.combo_lost .. " lost", DEAL.note } end
    if e.leaving and e.outcome ~= "walk_out" then d[#d + 1] = { "Out of patience", DEAL.note } end
  end
  return head, d
end
function R.deal_line(e)            -- the same as plain text (log, tests)
  local head, d = R.deal_parts(e)
  local t = {}
  for i, p in ipairs(d) do t[i] = p[1] end
  return head[1] .. (#t > 0 and (": " .. table.concat(t, ", ")) or "")
end
-- Where: the spot the buying / selling banner uses (between the Base Price plate and the bubble) — the dial is away
-- while the customer answers, so it is free, and nothing covers the item's picture.  The rows leave when the dial
-- (and the banner) comes back.
local DEAL_X, DEAL_Y = 304, 212
function R.show_deal(e, ticks)
  local head, d = R.deal_parts(e)
  R.deal_toasts = { ui.toast({ head }, { id = "rebalance.deal", x = DEAL_X, y = DEAL_Y, ticks = ticks or 240 }) }
  if #d > 0 then R.deal_toasts[2] = ui.toast(d, { id = "rebalance.deal2", x = DEAL_X, y = DEAL_Y + 24, ticks = ticks or 240, gap = 6 })
  else ui.toast("", { id = "rebalance.deal2", ticks = 0 }) end
end
game.customers.on_deal(function(e)
  R.last_deal = e
  remember(e)
  if cfg.get("deal_line") then
    R.last_line = R.deal_line(e)
    R.show_deal(e)
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
    return "A dungeon run from here takes 3 periods" .. ends_day(3) .. ". 2 for the run, 1 for the stop you made"
  elseif c.dungeon then
    return "A dungeon run takes 2 periods" .. ends_day(2) .. ". A stop on the way back takes 1 more"
  elseif c.later == 1 then
    return "Free to enter. The walk home will then take 1 period" .. ends_day(1)
  end
  return "No extra time: the walk home already takes 1 period"
end
local TRIP_ORDER = { face = "Comic Sans MS", px = 15, weight = 900, top = 0xffffff, bottom = 0xffc0d8, edge_rgb = 0x2a0018, edge = 2, shadow = 2, fat = 1 }
local TRIP = { face = "Comic Sans MS", px = 15, weight = 900, top = 0xffffff, bottom = 0xd8ecff, edge_rgb = 0x101828, edge = 2, shadow = 2, fat = 1 }
ui.on_draw(function()
  local line = R.trip_line()
  if not line then return end
  -- top middle of the map, a little in from the edge: one row per sentence (short rows stay clear of the clock and
  -- gold HUD on the left at 4:3); an order due today goes on the row under them
  local x, y = 344, 60
  for part in (line .. ". "):gmatch("(.-)%. ") do
    local l = ui.label(part, TRIP)
    if l then ui.draw_label(l, x, y) else ui.text(x, y - 8, part, 0xff7f7f7f, 0.8, "c") end
    y = y + 21
  end
end, "map")

-- ── 1.8b Order tracker: orders in progress stay on screen, and have a page in the pause menu ──
-- The indicator sits top right in the shop (free roam and while the store is open; away during a customer's
-- haggle, where the item's stats go) and on the town map: the soonest order and how many more there are.
local function when(o)
  return o.days < 0 and "overdue" or o.days == 0 and "today" or o.days == 1 and "tomorrow" or ("in " .. o.days .. " days")
end
function R.tracker_text()
  if not cfg.get("order_tracker") then return nil end
  local l = game.orders.list()
  local o = l[1]
  if not o then return nil end
  return ("Order %s: %s, %d %s"):format(when(o), o.name or "?", o.qty or 0, o.kind_name or "?") .. (#l > 1 and ("  +" .. (#l - 1) .. " more") or ""), o.days
end
local TRACK = {
  soon = { face = "Comic Sans MS", px = 14, weight = 900, top = 0xffffff, bottom = 0xffc0d8, edge_rgb = 0x2a0018, edge = 2, shadow = 2, fat = 1 },
  due  = { face = "Comic Sans MS", px = 15, weight = 900, top = 0xfff6a0, bottom = 0xff7a3a, edge_rgb = 0x2a0c00, edge = 2, shadow = 2, fat = 1 },
  far  = { face = "Comic Sans MS", px = 14, weight = 900, top = 0xffffff, bottom = 0xc9d4ff, edge_rgb = 0x14151c, edge = 2, shadow = 2, fat = 1 },
}
local function tracker_draw(y)
  local text, days = R.tracker_text()
  if not text then return end
  local l = ui.label(text, days <= 0 and TRACK.due or days == 1 and TRACK.soon or TRACK.far)
  if l then ui.draw_label(l, 632 - l.w / 2, y) end      -- right edge at 632
end
ui.on_draw(function()
  if game.customers.active() or game.scene.dialog() then return end
  tracker_draw(22)
end)
ui.on_draw(function() tracker_draw(22) end, "map")
function R.order_rows()
  local rows = {}
  for _, o in ipairs(game.orders.list()) do
    local w = when(o)
    rows[#rows + 1] = { label = ("%s: %d %s"):format(o.name or "?", o.qty or 0, o.kind_name or "?"), order = o.index,
                        value = function() return w end,
                        help = o.days <= 0 and "They come for it when you open the store" or "Have it in stock by then" }
  end
  if #rows == 0 then
    rows[1] = { label = "No orders", center = true, enabled = function() return false end, help = "Customers place them at the counter" }
  end
  return rows
end
local orders_page
function R.pages_sync()            -- the pages exist only while their rows are on; two pages share one pause entry
  local on = cfg.get("order_tracker") and true or false
  if on and not orders_page then
    orders_page = ui.page("pause", "Orders", {})
    orders_page.width = 400
    orders_page.on_open = function(p) p.rows = R.order_rows() end
  end
  if orders_page then orders_page.hidden = not on end
  ui.pause_label = (on and cfg.get("ledger") ~= "off") and "Notebook" or nil
end
ledger_sync()

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
  if R.deal_toasts then for _, t in ipairs(R.deal_toasts) do t.ticks = 0 end R.deal_toasts = nil end
  local l = ui.label(b[1], b[2])
  if l then ui.draw_label(l, 304, 216) else ui.text(304, 206, b[1], 0xff7f7f7f, 1, "c") end
end)

cfg.on_change(function(key) if key == "ledger" or key == "order_tracker" then ledger_sync() end end)
