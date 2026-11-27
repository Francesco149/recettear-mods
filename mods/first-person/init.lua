-- first-person — a camera mode at Recette's eyes (mod.game.camera.add_mode, loader API 1.6).
-- Cycle: retail 0 → retail 2 → [free] → first person → 0 (the save's camera dword stays 2 while it is on).
-- The look yaw is retail's own yaw (snapped, no ease) so camera-relative walking follows the view: W/A/S/D = the pad's
-- Up / Left / Down / Right; standing still, Recette faces where you look (her octant follows), so Z / left click
-- talks to what is in front.  Her billboard + shadow are hidden (render only); projection: horizontal FOV + near 0.1.
local cam, party, input, ui, cfg = mod.game.camera, mod.game.party, mod.input, mod.ui.native, mod.config
if not (cam and cam.set_projection and party) then mod.log("needs loader API 1.6 (camera.set_projection, mod.game.party)") return end
local P = input.PAD
local VK = { W = 0x57, A = 0x41, S = 0x53, D = 0x44, TAB = 0x09, LBUTTON = 0x01, RBUTTON = 0x02, BACK = 0x08 }
local DIRS = { { VK.W, P.U }, { VK.A, P.L }, { VK.S, P.D }, { VK.D, P.R } }
-- retail's keyboard binding index (recet.ini padNM, 1-based into the DIK table 0x5cbc2f) of each key: A..Z = 14..39
local KEYIDX = { [VK.W] = 36, [VK.A] = 14, [VK.S] = 32, [VK.D] = 17 }
local SLOTBIT = { 0x4, 0x1, 0x8, 0x2, 0x10, 0x20, 0x40, 0x80, 0x100 }   -- binding slot 0..8 → pad bit
local PITCH_MAX = 1.25
local TAU = 2 * math.pi
local function wrap(a) return a - TAU * math.floor((a + math.pi) / TAU) end
local function clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end

local st = { yaw = 0, pitch = -0.12, help = 0, blend = 1, captured = false, last_active = false }

-- which pad bits retail's own bindings give W/A/S/D (default: W = button E = the pause menu): swallowed while held
local function bound_bits(vk)
  local want, bits = KEYIDX[vk], 0
  for k = 0, 8 do if mod.mem.read_i16(0x438cce8 + 2 * k) == want then bits = bit.bor(bits, SLOTBIT[k + 1]) end end
  return bits
end

local function capture(on)
  if on ~= st.captured then input.capture(on); st.captured = on end
end
local ffi = require('ffi')
pcall(ffi.cdef, 'void *GetForegroundWindow(void);')
local UPTR = ffi.typeof('uintptr_t')
local function foreground()   -- capture the mouse only while the game window has the focus
  local fg = ffi.C.GetForegroundWindow()
  return fg ~= nil and tonumber(ffi.cast(UPTR, fg)) == mod.mem.read_u32(0x73dfc7c)
end

local function tick(active)
  local scene = mod.game.scene.id()
  local free = (active and mod.game.scene.free_roam()) and true or false   -- not a menu over the view
  st.free = free
  -- WASD drive the pad everywhere in the house (free roam, dialogs, menus, pause); retail's own W binding is swallowed
  if cam.house() or scene == 9 then
    local inj, eat = 0, 0
    for _, d in ipairs(DIRS) do
      if input.key(d[1]) then inj = bit.bor(inj, d[2]); eat = bit.bor(eat, bound_bits(d[1])) end
    end
    eat = bit.band(eat, bit.bnot(inj))
    if eat ~= 0 then input.consume(eat) end
    if inj ~= 0 then input.inject(inj) end
    if input.pressed(VK.TAB) then input.inject(P.Y) end                     -- menu (retail's button E)
    if input.pressed(VK.LBUTTON) then input.inject(P.A) end                 -- confirm / talk / pick up
    if input.pressed(VK.RBUTTON) then input.inject(free and P.Y or P.B) end     -- menu in free roam, back in menus
  end
  if not active then
    capture(false); party.hide_self(false); st.last_active = false
    return
  end
  if not st.last_active then st.blend = 0 end      -- (re)entering the free roam: ease in from retail's pose
  st.last_active = true
  party.hide_self(true)
  cam.set_projection{ hfov = clamp(cfg.get("fov") or 100, 70, 130), near = mod.screen.info().depth24 and 0.1 or 0.3 }
  if st.help > 0 then st.help = st.help - 1 end
  if not free then capture(false); return end      -- a menu over the first-person view: the mouse is the user's
  capture(foreground())
  local sens = (cfg.get("sensitivity") or 1) * 0.0025
  local m = input.mouse()
  if st.captured then
    st.yaw = wrap(st.yaw + m.dx * sens)            -- yaw up = turn right
    st.pitch = clamp(st.pitch - m.dy * sens * (cfg.get("invert_y") and -1 or 1), -PITCH_MAX, PITCH_MAX)
  end
  local pad = input.pad()                                                    -- pad: Skill 1/2 turn, 3/4 look
  if bit.band(pad, P.S1) ~= 0 then st.yaw = wrap(st.yaw - 0.045) end
  if bit.band(pad, P.S2) ~= 0 then st.yaw = wrap(st.yaw + 0.045) end
  if bit.band(pad, P.S3) ~= 0 then st.pitch = clamp(st.pitch + 0.03, -PITCH_MAX, PITCH_MAX) end
  if bit.band(pad, P.S4) ~= 0 then st.pitch = clamp(st.pitch - 0.03, -PITCH_MAX, PITCH_MAX) end
  if bit.band(pad, P.S5) ~= 0 or input.pressed(VK.BACK) then st.pitch = -0.12 end
  input.consume(P.S1 + P.S2 + P.S3 + P.S4 + P.S5)
  cam.set_yaw_offset(st.yaw, true)
  -- standing still: face the view (moving: retail's own camera-relative facing does it)
  if bit.band(input.mask(), 0xf) == 0 and bit.band(input.pad(), 0xf) == 0 then
    party.set_facing(wrap(-(cam.yaw_target() or 0)))
  end
end

local function pose(p)
  local pos = party.pos(0)
  if not pos[1] then return false end
  local yaw = p.yaw
  local cp = math.cos(st.pitch)
  local h = cfg.get("eye_height") or 2.6
  local ex, ey, ez = pos[1], pos[2] + h, pos[3]
  local tx, ty, tz = ex - math.sin(yaw) * cp * 4, ey + math.sin(st.pitch) * 4, ez + math.cos(yaw) * cp * 4
  local e, t = p.eye, p.target
  if st.blend < 1 then                               -- ease in from retail's pose (~12 frames)
    st.blend = math.min(1, st.blend + 0.08)
    local k = st.blend * st.blend * (3 - 2 * st.blend)
    ex, ey, ez = e[1] + (ex - e[1]) * k, e[2] + (ey - e[2]) * k, e[3] + (ez - e[3]) * k
    tx, ty, tz = t[1] + (tx - t[1]) * k, t[2] + (ty - t[2]) * k, t[3] + (tz - t[3]) * k
  end
  e[1], e[2], e[3] = ex, ey, ez
  t[1], t[2], t[3] = tx, ty, tz
  return true
end

local HELP = { "FIRST PERSON", "mouse : look      W A S D : walk", "left click : talk / confirm",
               "right click / Tab : menu", "Backspace : level the view", "Button 4 : next camera" }
local RET = { { 319, 232, 2, 5 }, { 319, 243, 2, 5 }, { 312, 239, 5, 2 }, { 323, 239, 5, 2 } }
local function draw()
  if st.blend >= 1 and st.free then                  -- reticle: a small outlined cross at the centre of retail's 640×480
    for _, r in ipairs(RET) do ui.fill(r[1] - 1, r[2] - 1, r[3] + 2, r[4] + 2, 0x90000000) end
    for _, r in ipairs(RET) do ui.fill(r[1], r[2], r[3], r[4], 0xe0ffffff) end
  end
  if st.help > 0 and st.free then ui.help_box(16, 150, HELP, nil, 0.7) end
end

cam.add_mode{
  name = "first_person", order = 20,
  on_enter = function()
    st.yaw = cam.yaw_offset() or 0; st.pitch = -0.12; st.blend = 0; st.last_active = false
    st.help = cfg.get("help") == "off" and 0 or 300
    mod.log("first person on")
  end,
  on_leave = function()
    capture(false); party.hide_self(false); cam.set_projection(nil)
    mod.log("first person off")
  end,
  on_tick = tick, pose = pose, draw = draw }
_G.first_person = st   -- tests / dev console

-- ── the "First Person" page in retail's Options (title + pause): live settings ──
local function range(a, b, d) local t = {} for v = a, b + 1e-9, d do t[#t + 1] = math.floor(v * 100 + 0.5) / 100 end return t end
local function near(vals, x) local best = vals[1] for _, v in ipairs(vals) do if math.abs(v - x) < math.abs(best - x) then best = v end end return best end
local function row(label, key, vals, fmt, help)
  local labels = {} for i, v in ipairs(vals) do labels[i] = fmt(v) end
  return ui.choice{ label = label, values = vals, labels = labels, help = help,
    get = function() return near(vals, cfg.get(key) or vals[1]) end,
    set = function(v) cfg.set(key, v) end }
end
if ui and ui.page then
  ui.page("options", "First Person", {
    row("Field of View", "fov", range(70, 130, 5), function(v) return ("%d"):format(v) end, "horizontal, at your screen's aspect"),
    row("Mouse Sensitivity", "sensitivity", range(0.2, 4, 0.2), function(v) return ("%.1f"):format(v) end),
    ui.choice{ label = "Invert Mouse Y", values = { false, true }, labels = { "OFF", "ON" }, wrap = true,
               get = function() return cfg.get("invert_y") and true or false end, set = function(v) cfg.set("invert_y", v) end },
    row("Eye Height", "eye_height", range(1.6, 3.4, 0.2), function(v) return ("%.1f"):format(v) end, "Recette is 3.4 tall"),
    ui.choice{ label = "Help on Entry", values = { "on", "off" }, labels = { "ON", "OFF" }, wrap = true,
               get = function() return cfg.get("help") == "off" and "off" or "on" end, set = function(v) cfg.set("help", v) end },
  })
end
