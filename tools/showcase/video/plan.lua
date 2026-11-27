-- the showcase video's clips: one run from the title into the shop (the newest save = a shop morning, free roam).
-- Run (loader repo): tools/win_steam.py TAG --mods display,first-person,free-camera,unlock-menu,wardrobe,dashboard,video
--   --encode 60 --secs 900 --cfg display=borderless vsync=on fps=60 aspect=fill fullbg=cover
--   --modcfg free-camera.help=off first-person.help=off display.fps=60
--   (preview: --encode 10 … video.step=6)
local cam = mod.game.camera
local ffi = require("ffi")
local function lerp(a, b, k) return a + (b - a) * k end

-- title: the unlocked menu, the cursor walks up to New Game and back
rec(200, 500, "title")
tap(250, "U .*24 U .*24 U .*50 D .*24 D .*24 D")
local t = tap(510, "A .*120 A .*120 A")
t = t + 380                                                  -- in the shop
tap(t - 120, "X")                                            -- Button 4: the game's low camera (mod modes hang off it)

-- wardrobe in the shop: presets live; Recette stands still at her spawn point (the edit insets a zoom on her)
rec(t, t + 380, "wardrobe")
for i, p in ipairs{ "Midnight", "Sakura", "Forest", "Original" } do
  at(t + i * 84, function() wardrobe.cfg.set("preset", p); wardrobe.apply() end)
end
t = t + 450

-- widescreen: the game's own 4:3, then 16:9 live
at(t - 60, function() mod.gfx.apply{ aspect = "4:3" } end)
rec(t, t + 420, "wide")
tap(t + 20, "L*45 .*30 R*45")
at(t + 170, function() mod.gfx.apply{ aspect = "fill" } end)
tap(t + 200, "R*50 .*20 D*30 .*20 L*50 U*30")
t = t + 450

-- free camera: turn + raise to a dollhouse view, walk, zoom in
at(t, function() cam.set_mode("free"); free_camera.yaw = 0; free_camera.dist = nil; free_camera.height = nil end)
rec(t, t + 540, "free")
anim(t + 40, t + 200, function(_, s) free_camera.yaw = lerp(0, 0.95, s); free_camera.dist = lerp(18, 22, s); free_camera.height = lerp(11.8, 20, s) end)
tap(t + 210, "L*40 .*10 R*40")
anim(t + 310, t + 500, function(_, s) free_camera.yaw = lerp(0.95, 0.15, s); free_camera.dist = lerp(22, 11, s); free_camera.height = lerp(20, 8, s) end)
t = t + 560
at(t, function() free_camera.yaw = 0; free_camera.dist = nil; free_camera.height = nil end)
t = t + 40

-- first person: look round from behind the counter, walk into the shop
at(t, function() cam.set_mode("first_person"); first_person.yaw = 0; first_person.pitch = -0.12 end)
rec(t, t + 600, "fp")
anim(t + 40, t + 150, function(_, s) first_person.yaw = lerp(0, -1.0, s) end)
anim(t + 160, t + 280, function(_, s) first_person.yaw = lerp(-1.0, 0.1, s); first_person.pitch = lerp(-0.12, -0.02, s) end)
tap(t + 285, "U*90")
anim(t + 300, t + 420, function(_, s) first_person.yaw = lerp(0.1, -0.7, s) end)
anim(t + 430, t + 520, function(_, s) first_person.yaw = lerp(-0.7, -1.5, s); first_person.pitch = lerp(-0.02, -0.15, s) end)
tap(t + 440, "U*60")
t = t + 620
at(t, function() cam.set_mode(nil) end)

-- the pause menu's Options: Display Settings, down to Frame Rate -> Auto (the clip ends there: interpolated frames
-- are not what this recorder takes, so the run goes back to stock pacing off camera)
local function esc() ffi.cast("void(__cdecl*)(void)", 0x45337b)() end     -- ESC: the pause list
t = t + 30
at(t + 20, esc)
local m = tap(t + 60, "D .*8 D .*8 A .*40 U .*10 R .*50")
m = tap(m, "D .*22 D .*22 D .*22 D .*22 D .*22 D .*22 D .*22 D .*40 R .*70")
rec(t, m, "display")
at(m + 5, function() mod.gfx.interp_set{ fps = 0 } end)
t = tap(m + 20, "B .*30 B .*30 B .*30 B .*40")

-- the Wardrobe page: presets, live preview
at(t + 20, esc)
m = tap(t + 60, "D .*8 D .*8 A .*40 U .*10 R .*20 R .*20 R .*50")
m = tap(m, "D .*40 R .*70 R .*70 R .*70 R .*40 R .*70 R .*70")
rec(t + 150, m, "wpage")
t = tap(m, "B .*30 B .*30 B .*30 B .*40")
t = t + 30

-- the developer overlay (ImGui) with a mod's dashboard
at(t, function() mod.ui.show(true) end)
rec(t, t + 300, "overlay")
tap(t + 60, "L*40 .*30 R*40")
at(t + 300, function() mod.ui.show(false) end)
t = t + 320

-- outro background: a slow turn of the dollhouse view
at(t, function() cam.set_mode("free"); free_camera.yaw = 0.65; free_camera.dist = 20; free_camera.height = 14 end)
rec(t + 40, t + 640, "outro")
anim(t, t + 640, function(k) free_camera.yaw = lerp(0.65, 0.05, k) end)
t = t + 660

-- the loader README's picture: the overlay + dashboard at the display's refresh rate, Recette in the Midnight preset
at(t, function() cam.set_mode(nil); free_camera.yaw = 0; free_camera.dist = nil; free_camera.height = nil
                 wardrobe.cfg.set("preset", "Midnight"); wardrobe.apply(); mod.gfx.interp_set{ fps = "auto" }; mod.ui.show(true) end)
at(t + 420, function() mod.log("showcase: shot readme_overlay", mod.screen.shot(mod.dir .. "readme_overlay.bmp")) end)
finish(t + 440)
