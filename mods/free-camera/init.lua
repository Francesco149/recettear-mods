-- free-camera — an extra mode in the shop's Button-4 camera cycle (mod.game.camera.add_mode, loader API 1.5).
-- Retail: 0 (standard) → 2 (low) → Free → 0.  The save's camera dword stays 2 while Free is on (saves stay vanilla).
-- Turning moves retail's own yaw target (so billboards, sprite facing and camera-relative walking follow, as in
-- retail's own camera turns); zoom / height re-place the eye around retail's target after retail's pose.
local cam, input, ui, cfg = mod.game.camera, mod.input, mod.ui.native, mod.config
local P = input.PAD
local VK = { LBR = 0xDB, RBR = 0xDD, PGUP = 0x21, PGDN = 0x22, HOME = 0x24, END = 0x23, BACK = 0x08 }
local DMIN, DMAX, HMIN, HMAX = 6, 40, 2, 40
local TURN, ZOOM, LIFT = 0.035, 0.30, 0.30           -- per tick while held (rad, units, units)
local PAD_BITS = P.S1 + P.S2 + P.S3 + P.S4 + P.S5

-- wanted view: yaw offset (rad); distance / height (nil = the game's own)
local st = { yaw = math.rad(cfg.get("yaw") or 0), dist = nil, height = nil, shown_d = nil, shown_h = nil,
             help = 0, dirty = false }
if (cfg.get("distance") or 0) > 0 then st.dist = cfg.get("distance") end
if (cfg.get("height") or 0) > 0 then st.height = cfg.get("height") end

local function clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end
local function save()
  cfg.set("yaw", math.deg(st.yaw)); cfg.set("distance", st.dist or 0); cfg.set("height", st.height or 0)
  st.dirty = false
end
local function reset() st.yaw, st.dist, st.height = 0, nil, nil; st.dirty = true end

local last_R, last_H = 18, 11.8                     -- retail's mode-2 orbit (the pose post refreshes them)
local function tick(active)
  if not active then return end
  local busy = false
  local turn, zoom, lift = 0, 0, 0
  if input.key(VK.LBR) then turn = turn + 1 end
  if input.key(VK.RBR) then turn = turn - 1 end
  if input.key(VK.PGUP) then zoom = zoom - 1 end
  if input.key(VK.PGDN) then zoom = zoom + 1 end
  if input.key(VK.HOME) then lift = lift + 1 end
  if input.key(VK.END) then lift = lift - 1 end
  local pad = input.pad()
  if bit.band(pad, P.S1) ~= 0 then turn = turn + 1 end
  if bit.band(pad, P.S2) ~= 0 then turn = turn - 1 end
  if bit.band(pad, P.S3) ~= 0 then zoom = zoom - 1 end
  if bit.band(pad, P.S4) ~= 0 then zoom = zoom + 1 end
  if bit.band(pad, P.S5) ~= 0 or input.pressed(VK.BACK) then reset() end
  input.consume(PAD_BITS)                             -- Skill buttons are camera keys while Free is on
  local m = input.mouse()
  if bit.band(m.buttons, 2) ~= 0 and m.dx ~= 0 then st.yaw = st.yaw + m.dx * 0.008; busy = true end
  if m.wheel ~= 0 then zoom = zoom - m.wheel * 5 end   -- notches (1.5 units each)
  if turn ~= 0 then st.yaw = st.yaw + turn * TURN; busy = true end
  if zoom ~= 0 then st.dist = clamp((st.dist or last_R) + zoom * ZOOM, DMIN, DMAX); busy = true end
  if lift ~= 0 then st.height = clamp((st.height or last_H) + lift * LIFT, HMIN, HMAX); busy = true end
  local tau = 2 * math.pi
  st.yaw = st.yaw - tau * math.floor((st.yaw + math.pi) / tau)
  cam.set_yaw_offset(st.yaw)
  if busy then st.dirty = true elseif st.dirty then save() end
  if st.help > 0 then st.help = st.help - 1 end
end

local function ease(shown, want) if shown == nil then return want end return shown + (want - shown) * 0.25 end
local function pose(p)
  last_R, last_H = p.R, p.H
  if st.dist == nil and st.height == nil and st.shown_d == nil and st.shown_h == nil then return false end
  -- eased toward the wanted orbit; back to nil (= the game's) once there
  st.shown_d = ease(st.shown_d, st.dist or p.R); st.shown_h = ease(st.shown_h, st.height or p.H)
  if st.dist == nil and math.abs(st.shown_d - p.R) < 1e-3 then st.shown_d = nil end
  if st.height == nil and st.shown_h and math.abs(st.shown_h - p.H) < 1e-3 then st.shown_h = nil end
  local e, t = p.eye, p.target
  local k = (st.shown_d or p.R) / (p.R ~= 0 and p.R or 1)
  e[1] = t[1] + (e[1] - t[1]) * k
  e[3] = t[3] + (e[3] - t[3]) * k
  e[2] = e[2] + ((st.shown_h or p.H) - p.H)
  return true
end

local HELP = { "FREE CAMERA", "[ ]  /  right-drag : turn", "PgUp / PgDn / wheel : zoom",
               "Home / End : height", "Backspace : reset", "Button 4 : next camera" }
local function draw()
  if st.help <= 0 then return end
  ui.help_box(16, 150, HELP, nil, 0.7)   -- under the day dial, above the merchant level
end

cam.add_mode{
  name = "free", order = 10,
  on_enter = function() st.help = cfg.get("help") == "off" and 0 or 300; st.shown_d, st.shown_h = nil, nil
                        mod.log("free camera on") end,
  on_leave = function() if st.dirty then save() end; mod.log("free camera off") end,
  on_tick = tick, pose = pose, draw = draw }
_G.free_camera = st   -- tests / dev console
