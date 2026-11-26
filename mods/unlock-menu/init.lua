-- unlock-menu — the full title menu whatever the saves hold.  Spec: docs/mods/unlock-menu.md.
--
-- Retail builds the title rows in 0x49a43d from the unlock scan 0x49a324 (bit0 = a cleared save,
-- bit1 = one holding a clear item).  We hook that ONE call (a call-site redirect: the scan itself
-- still runs and still fills the per-bank clear-item bytes 0x96432f4) and return 3, so the rows are
-- NEW GAME / NEW GAME + / SURVIVAL MODE / [LOAD GAME] / ITEM ENCYCLOPEDIA / SURVIVAL SCORE / OPTIONS / EXIT.
-- Nothing is written to a save bank: remove the mod and the vanilla menu is back.
--
-- NEW GAME +: retail's picker 0x49b4f4 lists banks with GAME_MODE 3 + a clear item; its confirm then
-- only checks that the bank is occupied, so widening the list to every occupied bank is enough.
-- SURVIVAL keeps retail's rule (its confirm re-checks GAME_MODE 3 on the source bank — overriding
-- that would mean editing the save, invariant 8).
local mem, sym = mod.mem, mod.sym

if mod.config.get("mode") == "vanilla" then mod.log("mode = vanilla: off") return end
local scan, picker = sym.va("title_unlock_mask"), sym.va("title_picker_filter")
if not scan or not picker then mod.log("title symbols unverified on this exe — off") return end

local CODES, CURSOR = 0x9643358, 0x9643540          -- title row codes [8], cursor row
local LIST, COUNT = 0x9643380, 0x5d1bbc             -- picker bank list [100], count
local OCCUPIED, STRIDE = 0x56e6288, 0x2dfc8         -- bank b occupied: i32 at OCCUPIED + b*STRIDE > 0

local n = 0
for _, site in ipairs(mod.hook.calls_to(scan)) do
  -- only the row build's call: the scan's other caller keeps the real mask
  if sym.name_at(site) == "title_build" then
    mod.hook.callsite(site, { post = function(c) c.eax = 3 end })
    n = n + 1
  end
end

if mod.config.get("any_save_ng_plus") then
  for _, site in ipairs(mod.hook.calls_to(picker)) do
    mod.hook.callsite(site, { post = function()
      if mem.read_i32(CODES + 4 * mem.read_i32(CURSOR)) ~= 4 then return end   -- NEW GAME + only
      local k = 0
      for b = 0, 99 do
        if mem.read_i32(OCCUPIED + b * STRIDE) > 0 then mem.write_i32(LIST + 4 * k, b); k = k + 1 end
      end
      mem.write_i32(COUNT, k)
    end })
  end
end
mod.log(("title unlock armed (%d row-build site(s)); NG+ from any save: %s"):format(n, tostring(mod.config.get("any_save_ng_plus"))))
