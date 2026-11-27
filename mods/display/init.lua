-- display — the Display Settings page (spec: docs/mods/display.md).  Rows apply through mod.gfx.apply (loader:
-- live; the device rows through retail's own Reset path).  Display mode / resolution / render scale are staged and
-- applied with Button 1 (one Reset, not one per step); aspect, backgrounds, HUD anchor and VSYNC apply at once.
-- Saved in rml_mods.cfg (display.*); unset keys leave rml_loader.cfg in charge.
local ui, gfx, cfg = mod.ui.native, mod.gfx, mod.config
if not (ui and gfx) then mod.log("needs loader API 1.4 (mod.ui.native, mod.gfx)") return end

-- ── saved settings → the loader at start ──
local boot = {}
local function res_of(s)
  if s == "native" then return 0, 0 end
  local w, h = tostring(s or ""):match("^(%d+)x(%d+)$")
  return tonumber(w), tonumber(h)
end
if cfg.get("display") ~= "" then boot.display = cfg.get("display") end
do local w, h = res_of(cfg.get("resolution")); if w then boot.width, boot.height = w, h end end
if cfg.get("aspect") ~= "" then boot.aspect = cfg.get("aspect") end
if cfg.get("fullbg") ~= "" then boot.fullbg = cfg.get("fullbg") end
if cfg.get("hud") >= 0 then boot.hud = cfg.get("hud") end
if cfg.get("scale") > 0 then boot.scale = cfg.get("scale") end
if cfg.get("vsync") ~= "" then boot.vsync = cfg.get("vsync") end
if gfx.interp_set and cfg.get("fps") ~= "" then   -- frame rate: interpolation, no Reset needed
  local v = cfg.get("fps")
  gfx.interp_set{ fps = v == "auto" and "auto" or (tonumber(v) or 60) > 60 and tonumber(v) or 0 }
end
if next(boot) then
  local ok, how = gfx.apply(boot)
  mod.log(("saved settings applied at start: %s"):format(ok and how or tostring(how)))
end

-- ── what the page shows ──
local function info() return mod.screen.info() end
local function wanted() return gfx.wanted() end
local staged = {}   -- display / width,height / scale waiting for Button 1

local function cur_display() return staged.display or info().display end
local function cur_res()
  if staged.width then return staged.width, staged.height end
  local w = wanted()
  if w.width > 0 then return w.width, w.height end
  return 0, 0
end
local function cur_scale() return staged.scale or info().scale end

local WINDOW_SIZES = { {640,480}, {800,600}, {960,720}, {1024,768}, {1280,720}, {1280,960}, {1366,768}, {1440,1080},
                       {1600,900}, {1920,1080}, {2560,1440}, {3840,2160} }
local function res_list()
  local mon = gfx.monitor()
  local d, t = cur_display(), {}
  if d == "borderless" then return { {0, 0} } end
  if d == "exclusive" then
    local seen = {}
    t[1] = {0, 0}
    for _, m in ipairs(gfx.modes()) do
      local k = m.w .. "x" .. m.h
      if not seen[k] and m.w >= 640 and m.h >= 480 then seen[k] = true; t[#t + 1] = { m.w, m.h } end
    end
    table.sort(t, function(a, b) return a[1] * a[2] < b[1] * b[2] or (a[1] * a[2] == b[1] * b[2] and a[1] < b[1]) end)
    return t
  end
  for _, s in ipairs(WINDOW_SIZES) do
    if not mon.w or (s[1] <= mon.w and s[2] <= mon.h) then t[#t + 1] = s end
  end
  return t
end
local function res_label(w, h)
  if w == 0 then return "Native" end
  return ("%dx%d"):format(w, h)
end
local function native_help()
  local m = gfx.monitor()
  return m.w and ("Native = the monitor, %dx%d"):format(m.w, m.h) or "Native = the monitor"
end

local function dirty() return staged.display ~= nil or staged.width ~= nil or staged.scale ~= nil end
local function apply_staged()
  if not dirty() then return end
  local t = { display = staged.display, width = staged.width, height = staged.height, scale = staged.scale }
  local ok, how = gfx.apply(t)
  mod.log(("apply %s %s %s: %s"):format(tostring(t.display), tostring(t.width and (t.width .. "x" .. t.height)),
          tostring(t.scale), ok and how or tostring(how)))
  if ok then
    if t.display then cfg.set("display", t.display) end
    if t.width then cfg.set("resolution", t.width == 0 and "native" or (t.width .. "x" .. t.height)) end
    if t.scale then cfg.set("scale", t.scale) end
  end
  staged = {}
end
local function staged_mark(on) return on and "*" or "" end
local APPLY_HELP = "Button 1: apply"

local DISPLAY = { "windowed", "borderless", "exclusive" }
local DISPLAY_L = { windowed = "Windowed", borderless = "Borderless", exclusive = "Fullscreen" }

local rows = {
  { label = "Display Mode",
    value = function() return DISPLAY_L[cur_display()] .. staged_mark(staged.display) end,
    step = function(dir)
      local d, i = cur_display(), 1
      for k, v in ipairs(DISPLAY) do if v == d then i = k end end
      i = (i - 1 + dir) % #DISPLAY + 1
      staged.display = DISPLAY[i] ~= info().display and DISPLAY[i] or nil
      if DISPLAY[i] ~= "windowed" then staged.width, staged.height = 0, 0 else staged.width, staged.height = nil, nil end
      if not staged.display and staged.width == 0 and wanted().width == 0 then staged.width, staged.height = nil, nil end
    end,
    activate = apply_staged,
    help = function() return dirty() and APPLY_HELP or "Windowed / Borderless / Fullscreen" end },
  { label = "Resolution",
    value = function() local w, h = cur_res(); return res_label(w, h) .. staged_mark(staged.width) end,
    enabled = function() return cur_display() ~= "borderless" end,
    step = function(dir)
      local list, w, h = res_list(), cur_res()
      local i
      for k, s in ipairs(list) do if s[1] == w and s[2] == h then i = k end end
      if not i then i = dir > 0 and 0 or #list + 1 end
      i = i + dir
      if i < 1 or i > #list then return false end
      staged.width, staged.height = list[i][1], list[i][2]
    end,
    activate = apply_staged,
    help = function() return dirty() and APPLY_HELP or native_help() end },
  { label = "Render Scale",
    value = function() return ("%dx"):format(cur_scale()) .. staged_mark(staged.scale) end,
    enabled = function() return info().backend == 9 end,
    step = function(dir)
      local s = cur_scale() + dir
      if s < 1 or s > 4 then return false end
      staged.scale = s ~= info().scale and s or nil
    end,
    activate = apply_staged,
    help = function() return dirty() and APPLY_HELP or "Supersampling (sharper, slower)" end },
  ui.choice{ label = "Aspect Ratio",
    values = { "fill", "4:3", "16:10", "16:9", "21:9" }, labels = { "Auto", "4:3", "16:10", "16:9", "21:9" },
    get = function()
      local a = wanted().aspect
      if a == "fill" or a == "4:3" then return a end
      local n = tonumber(a) or 0
      for _, k in ipairs({ "16:10", "16:9", "21:9" }) do
        local x, y = k:match("(%d+):(%d+)")
        if math.abs(n - x / y) < 0.01 then return k end
      end
      return a
    end,
    set = function(v) local ok = gfx.apply{ aspect = v }; if ok then cfg.set("aspect", v) end end,
    help = "Auto = the screen's shape" },
  ui.choice{ label = "Backgrounds",
    values = { "auto", "pillar", "cover", "stretch" }, labels = { "Auto", "Pillarbox", "Zoom+Crop", "Stretch" },
    get = function() return wanted().fullbg end,
    set = function(v) gfx.apply{ fullbg = v }; cfg.set("fullbg", v) end,
    enabled = function() return info().wide end,
    help = "Widescreen: full-screen pictures" },
  ui.choice{ label = "HUD Anchor",
    values = { 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 },
    labels = { "0%", "10%", "20%", "30%", "40%", "50%", "60%", "70%", "80%", "90%", "100%" },
    get = function() return wanted().hud end,
    set = function(v) gfx.apply{ hud = v }; cfg.set("hud", v) end,
    enabled = function() return info().wide end,
    help = "0% = centre, 100% = screen edges" },
  ui.choice{ label = "VSYNC", values = { 1, 0 }, labels = { "ON", "OFF" }, wrap = true,
    get = function() return info().vsync end,
    set = function(v) local ok = gfx.apply{ vsync = v == 1 }; if ok then cfg.set("vsync", v == 1 and "on" or "off") end end },
  ui.choice{ label = "Frame Rate",
    values = { "60", "auto", "120", "144", "165", "240" }, labels = { "60", "Auto", "120", "144", "165", "240" },
    get = function()
      local f = gfx.interp and gfx.interp().fps or 0
      return f == 0 and "60" or f < 0 and "auto" or tostring(f)
    end,
    set = function(v)
      if not gfx.interp_set then return end
      gfx.interp_set{ fps = v == "auto" and "auto" or v == "60" and 0 or tonumber(v) }
      cfg.set("fps", v)
    end,
    enabled = function() return info().backend == 9 and gfx.interp_set ~= nil end,
    help = function()
      local hz = gfx.monitor().hz
      return "Auto = the monitor" .. ((hz or 0) > 1 and (" (" .. hz .. " Hz)") or "") .. "; above 60 = interpolated"
    end },
  { label = "HD Textures", value = function() return "n/a" end, enabled = function() return false end,
    help = "No HD pack generated" },
  { label = "Sprite Filter", value = function() return "Point" end, enabled = function() return false end,
    help = "Retail's point sampling" },
}
ui.page("options", "Display Settings", rows)
