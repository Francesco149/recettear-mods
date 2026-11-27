-- rebalance — Rebalance + QoL (design: docs/mods/rebalance.md).  The mod holds policy and numbers; everything it
-- needs from the engine is loader API (mod.config pages + presets, mod.store, pause-menu pages, mod.game.*).
-- Built so far: 1.1 customer ledger, 1.6 buying / selling banner.
local ui, cfg, game = mod.ui.native, mod.config, mod.game
if not (ui and ui.on_draw and cfg.page and game.customers and game.customers.roster) then
  mod.log("needs loader API 1.12") return
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
      rows[#rows + 1] = {
        label = c.name, customer = c.id,
        value = function() return rep end,
        help = full and ("Pays up to %s pix now, %s at Lv 10"):format(commas(c.budget), commas(c.budget_hi))
               or (c.level >= 10 and "As loyal as they get" or ("%d more point%s to Lv %d"):format(c.to_next, c.to_next == 1 and "" or "s", c.level + 1)),
      }
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

-- ── 1.6 Buying or selling, while the price dial is up ──
-- Every customer machine shows the dial in state 6.  Kind 0 = the customer sells to you (you pay); 1 = a request
-- ("something to …"), 2 = an item off your shelves, 4 / 5 = an order picked up: you sell.  3 (placing an order) has
-- no price.
local BANNER = {
  [0] = { "You are buying",  { face = "Comic Sans MS", px = 22, weight = 900, top = 0xffe9a0, bottom = 0xff8c1a, edge_rgb = 0x4a1c06, edge = 1, shadow = 2, fat = 2 } },
  sell  = { "You are selling", { face = "Comic Sans MS", px = 22, weight = 900, top = 0xe6ffd0, bottom = 0x4fc23a, edge_rgb = 0x123a10, edge = 1, shadow = 2, fat = 2 } },
}
BANNER[1], BANNER[2], BANNER[4], BANNER[5] = BANNER.sell, BANNER.sell, BANNER.sell, BANNER.sell
function R.banner()
  if not cfg.get("deal_banner") then return nil end
  local c = game.customers.active() and game.customers.current()
  if not c or c.state ~= 6 then return nil end
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
