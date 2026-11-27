-- tools/showcase/video — the showcase video's gameplay clips from one scripted run of the real game (not an
-- installable mod: the loader's tools/win_steam.py --mods …,video --encode 60 stages it beside the real mods).
-- plan.lua says what happens at which tick: taps (one token per tick), Lua, animations and clips.  A clip = one BMP
-- per tick (NAME_00001.bmp …, the output as the player sees it); the game runs as slow as the disk writes, the clip
-- stays one frame per tick = 60 fps.  done.txt ends the run (win_steam polls for it).  What must run in real time
-- (the overlay's own fps line) is recorded off the desktop instead: plan_overlay.lua with win_steam.py --grab.
local BTN = { R = 0x1, L = 0x2, U = 0x4, D = 0x8, A = 0x10, B = 0x20, C = 0x40, X = 0x80, Y = 0x100 }
local q, at, clips = {}, {}, {}
local step = tonumber(mod.config.get("step")) or 1
local P = {}
function P.tap(t, s)                 -- queue taps from tick t; returns the tick after the last
  local i = t
  for tok in s:gmatch("%S+") do
    local body, n = tok:match("^(.-)%*(%d+)$")
    body = body or tok; n = tonumber(n) or 1
    local m = 0
    if body ~= "." then for c in body:gmatch(".") do m = m + (BTN[c] or 0) end end
    for _ = 1, n do q[i] = (q[i] or 0) + m; i = i + 1 end
  end
  return i
end
function P.at(t, fn) at[t] = at[t] or {}; table.insert(at[t], fn) end
function P.anim(t0, t1, fn)          -- fn(k, s) each tick of [t0, t1]: k linear 0..1, s smoothstep
  for t = t0, t1 do
    local k = (t - t0) / math.max(1, t1 - t0)
    P.at(t, function() fn(k, k * k * (3 - 2 * k)) end)
  end
end
function P.rec(t0, t1, name) clips[#clips + 1] = { t0 = t0, t1 = t1, name = name, n = 0 } end
function P.finish(t) P.at(t, function() local f = io.open(mod.dir .. "done.txt", "w"); f:write("done\n"); f:close() end) end
setmetatable(P, { __index = getfenv(1) })   -- this mod's env (mod.*), then _G (the other mods' globals)
local chunk, err = loadfile(mod.dir .. (mod.config.get("plan") or "plan") .. ".lua")   -- video.plan = another plan file
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
  for _, c in ipairs(clips) do
    if t >= c.t0 and t <= c.t1 and (t - c.t0) % step == 0 then
      c.n = c.n + 1
      if not mod.screen.shot(("%s%s_%05d.bmp"):format(mod.dir, c.name, c.n)) then mod.log(("showcase: %s frame %d not queued"):format(c.name, c.n)) end
      if t + step > c.t1 then mod.log(("showcase: clip %s %d frames, presents %d"):format(c.name, c.n, mod.screen.presents())) end
    end
  end
end)
