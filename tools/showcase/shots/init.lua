-- tools/showcase/shots — the README's screenshots from one scripted run of the real game (not an installable mod:
-- the loader's tools/win_steam.py --mods showcase_shots stages it beside the real mods).  plan.lua lists what
-- happens at which tick: taps (rd-style, one token per tick), Lua, and shots (BMPs in this folder; shots.py turns the
-- fetched ones into docs/img/*.jpg).
local BTN = { R = 0x1, L = 0x2, U = 0x4, D = 0x8, A = 0x10, B = 0x20, C = 0x40, X = 0x80, Y = 0x100 }
local q, at = {}, {}
local P = {}
function P.tap(t, s)                 -- queue taps from tick t
  local i = t
  for tok in s:gmatch("%S+") do
    local body, n = tok:match("^(.-)%*(%d+)$")
    body = body or tok; n = tonumber(n) or 1
    local m = 0
    if body ~= "." then for c in body:gmatch(".") do m = m + (BTN[c] or 0) end end
    for _ = 1, n do q[i] = m; i = i + 1 end
  end
end
function P.at(t, fn) at[t] = at[t] or {}; table.insert(at[t], fn) end
function P.shot(t, name) P.at(t, function() mod.log("showcase: shot " .. name, mod.screen.shot(mod.dir .. name .. ".bmp")) end) end
setmetatable(P, { __index = getfenv(1) })   -- this mod's env (mod.*), then _G (the other mods' globals)
local chunk, err = loadfile(mod.dir .. "plan.lua")
if not chunk then mod.log("showcase: " .. tostring(err)) return end
setfenv(chunk, P)
local ok, e = pcall(chunk)
if not ok then mod.log("showcase: plan: " .. tostring(e)) return end
mod.on_tick(function()
  local t = mod.tick()
  local m = q[t]; if m and m ~= 0 then mod.input.inject(m) end
  for _, fn in ipairs(at[t] or {}) do
    local ok2, e2 = pcall(fn)
    if not ok2 then mod.log(("showcase: tick %d: %s"):format(t, tostring(e2))) end
  end
end)
