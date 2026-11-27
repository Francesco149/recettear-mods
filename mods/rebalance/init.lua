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

-- ── 1.6 Buying or selling, in large, while the price dial is up ──
-- kind 0 = the customer sells to you (you pay), 1 / 3.. = requests and orders, 2 = they buy from your shelves.
local BANNER = { [0] = { "YOU ARE BUYING", 0xff7f5020 }, [2] = { "YOU ARE SELLING", 0xff307f30 } }
function R.banner()
  if not cfg.get("deal_banner") then return nil end
  local c = game.customers.active() and game.customers.current()
  if not c or c.state_name ~= "price" then return nil end
  return BANNER[c.kind]
end
ui.on_draw(function()
  local b = R.banner()
  if not b then return end
  for _, o in ipairs({ { -2, 0 }, { 2, 0 }, { 0, -2 }, { 0, 2 } }) do ui.text(320 + o[1], 28 + o[2], b[1], 0xff101010, 1.4, "c", "x1") end
  ui.text(320, 28, b[1], b[2], 1.4, "c")
end)

cfg.on_change(function(key) if key == "ledger" then ledger_sync() end end)
