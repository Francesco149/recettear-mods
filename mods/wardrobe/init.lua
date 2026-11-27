-- wardrobe — recolour Recette by region (spec: docs/mods/wardrobe.md).  The pixels never pass through Lua: the
-- loader's asset layer (mod.assets.recolor, core/recolor.h) segments each picture from regions.txt (colour seeds
-- + rects, no pixels) and recolours it in C as retail loads it; a change reloads the resident ones (the field sheet).
local A, cfg = mod.assets, mod.config
if not (A and A.recolor) then mod.log("needs loader API 1.8 (mod.assets.recolor)") return end

local function read(name)
  local f = io.open(mod.dir .. name, "rb")
  if not f then return nil end
  local s = f:read("*a"); f:close(); return s
end

local regions, images = A.recolor("wardrobe", read("regions.txt") or "")
if not regions then mod.log("regions.txt: " .. tostring(images)) return end

-- palettes.txt: "palette NAME" then "REGION #rrggbb" lines
local palettes, order = {}, {}
do
  local cur
  for ln in (read("palettes.txt") or ""):gmatch("[^\r\n]+") do
    if not ln:match("^%s*#") then
      local name = ln:match("^%s*palette%s+(.-)%s*$")
      if name then cur = {}; palettes[name] = cur; order[#order + 1] = name
      elseif cur then
        local r, hex = ln:match("^%s*(%S+)%s+#?(%x%x%x%x%x%x)")
        if r then cur[r] = "#" .. hex:lower() end
      end
    end
  end
end

local W = { regions = regions, images = images, palettes = palettes, order = order }

-- current colours: region id → "#rrggbb" (absent = Original)
function W.colours()
  local p = cfg.get("preset") or "Original"
  local t = {}
  if p == "Custom" then
    for _, r in ipairs(regions) do
      local v = cfg.get(r.id)
      if type(v) == "string" and v:match("^#%x%x%x%x%x%x$") then t[r.id] = v:lower() end
    end
  elseif palettes[p] then
    for k, v in pairs(palettes[p]) do t[k] = v end
  end
  return t
end

-- push the colours to the loader + reload what is resident; returns slots reloaded
function W.apply(t)
  A.recolor_set("wardrobe", t or W.colours())
  local n = 0
  for _, g in ipairs(images) do n = n + A.reload(g) end
  return n
end

W.apply()

-- ── the page (title + pause Options): Preset, one row per region, Reset All ──
local ui = mod.ui.native
local COLOURS = { "#1c1c1c", "#3b3b3b", "#8a8a8a", "#c8c8c8", "#f4f4f4", "#f3e9d2", "#e8c872", "#d4a017", "#e07b28",
                  "#a0451c", "#6b3a1e", "#3e2513", "#c0262c", "#8b1a2b", "#f2a7c3", "#c2387a", "#7d4cad", "#b79fe0",
                  "#22356b", "#3a6ea5", "#8ecae6", "#2a9d8f", "#2f7a3d", "#9bc53d", "#6b7a2a" }
local SKIN = { "#fde7d6", "#f6d1b8", "#f1c27d", "#e0ac69", "#c68642", "#8d5524", "#5c3a21", "#d9e6f2", "#b8e0c8" }
local MODES = { "palette", "hue", "light", "sat" }
local mode = {}   -- region id → index into MODES (Button 3 cycles)

local function hex2rgb(h) local v = tonumber(h:sub(2), 16); return bit.rshift(v, 16) % 256, bit.rshift(v, 8) % 256, v % 256 end
local function rgb2hex(r, g, b) return ("#%02x%02x%02x"):format(r, g, b) end
local function rgb2hsl(r, g, b)
  r, g, b = r / 255, g / 255, b / 255
  local mx, mn = math.max(r, g, b), math.min(r, g, b)
  local l, h, s = (mx + mn) / 2, 0, 0
  if mx ~= mn then
    local d = mx - mn
    s = l > 0.5 and d / (2 - mx - mn) or d / (mx + mn)
    if mx == r then h = (g - b) / d + (g < b and 6 or 0) elseif mx == g then h = (b - r) / d + 2 else h = (r - g) / d + 4 end
    h = h / 6
  end
  return h, s, l
end
local function hsl2rgb(h, s, l)
  local function f(p, q, t)
    t = t % 1
    if t < 1 / 6 then return p + (q - p) * 6 * t elseif t < 0.5 then return q
    elseif t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
    return p
  end
  local r, g, b
  if s == 0 then r, g, b = l, l, l else
    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    r, g, b = f(p, q, h + 1 / 3), f(p, q, h), f(p, q, h - 1 / 3)
  end
  local function c(v) return math.max(0, math.min(255, math.floor(v * 255 + 0.5))) end
  return c(r), c(g), c(b)
end

local last_apply, dirty = -100, false
local function changed() dirty = true end
mod.on_frame(function()
  if dirty and mod.frame() - last_apply >= 6 then dirty = false; last_apply = mod.frame(); W.apply() end
end)

-- editing a region from a preset: the preset's colours become Custom first
local function to_custom()
  if cfg.get("preset") == "Custom" then return end
  local cur = W.colours()
  for _, r in ipairs(regions) do cfg.set(r.id, cur[r.id] or "") end
  cfg.set("preset", "Custom")
end
function W.set(id, hex) to_custom(); cfg.set(id, hex or ""); changed() end

local rows = {}
local presets = { "Original" }
for _, n in ipairs(order) do presets[#presets + 1] = n end
presets[#presets + 1] = "Custom"
rows[#rows + 1] = ui.choice{ label = "Preset", values = presets, wrap = true,
  get = function() return cfg.get("preset") or "Original" end,
  set = function(v) cfg.set("preset", v); changed() end,
  help = "Left / Right: Original, presets, your Custom colours" }
for _, r in ipairs(regions) do
  local list = r.id == "skin" and SKIN or COLOURS
  local row = { label = r.name }
  function row.value()
    local c = W.colours()[r.id]
    local m = MODES[mode[r.id] or 1]
    if not c then return "Original" end
    return (m == "palette" and "" or (m .. " ")) .. c:upper()
  end
  function row.swatch()
    local c = W.colours()[r.id]
    if not c then return nil end
    return 0xff000000 + tonumber(c:sub(2), 16)
  end
  function row.step(dir)
    local c = W.colours()[r.id]
    local m = MODES[mode[r.id] or 1]
    if m == "palette" or not c then
      local i = 0   -- 0 = Original
      for k, v in ipairs(list) do if v == c then i = k end end
      if c and i == 0 then   -- an edited colour: the nearest palette step in that direction starts from the ends
        i = dir > 0 and 0 or #list + 1
      end
      i = (i + dir) % (#list + 1)
      W.set(r.id, i == 0 and "" or list[i])
      return true
    end
    local h, s, l = rgb2hsl(hex2rgb(c))
    if m == "hue" then h = (h + dir / 36) % 1
    elseif m == "light" then l = math.max(0.03, math.min(0.97, l + dir * 0.04))
    else s = math.max(0, math.min(1, s + dir * 0.05)) end
    W.set(r.id, rgb2hex(hsl2rgb(h, s, l)))
    return true
  end
  function row.alt() mode[r.id] = (mode[r.id] or 1) % #MODES + 1 end
  function row.help()
    local m = MODES[mode[r.id] or 1]
    if m == "palette" then return "Left / Right: colours (Original first)  -  Button 3: fine edit" end
    return ("Left / Right: %s  -  Button 3: %s"):format(m, MODES[(mode[r.id] or 1) % #MODES + 1])
  end
  rows[#rows + 1] = row
end
rows[#rows + 1] = ui.button{ label = "Reset All", center = true, help = "Every region back to the original colours",
  activate = function()
    cfg.set("preset", "Original")
    for _, r in ipairs(regions) do cfg.set(r.id, ""); mode[r.id] = nil end
    changed()
  end }

local page = ui.page("options", "Wardrobe", rows, mod.name)
-- live preview: her field sprite, front + back (each a 64x32 head strip over its 64x32 body strip on the sheet),
-- left of the panel; the sheet is resident, so a change shows as soon as it reloads
local SHEET = "bmp/chr/chr00.bmp"
local FIGS = { { { 128, 32, 192, 64 }, { 128, 0, 192, 32 } }, { { 0, 0, 64, 32 }, { 0, 32, 64, 64 } } }
page.draw = function(sx, by)
  local slot = ui.slot(SHEET)
  if not slot then return end
  ui.fill(sx + 14, by + 88, 132, 276, 0x80201008)
  for k, fig in ipairs(FIGS) do
    local y = by + 92 + (k - 1) * 136
    for j, q in ipairs(fig) do ui.quad(slot, sx + 16, y + (j - 1) * 64, 128, 64, q[1], q[2], q[3], q[4], 0xffffffff) end
  end
end
W.page = page

mod.log(("%d regions, %d image rules, %d presets; preset %s"):format(#regions, #images, #order, cfg.get("preset") or "?"))
W.cfg = cfg
_G.wardrobe = W   -- tests / the page
