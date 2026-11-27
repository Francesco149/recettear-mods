-- the README's pictures: one run from the title into the shop (the newest save = a shop morning, free roam).
-- Run (loader repo): tools/win_steam.py TAG --mods display,first-person,free-camera,unlock-menu,wardrobe,shots --secs 60
--   --cfg display=borderless vsync=on fps=auto aspect=fill fullbg=cover --modcfg free-camera.help=off first-person.help=off
local cam = mod.game.camera
local ffi = require("ffi")
shot(230, "title_menu")
tap(240, "A .*120 A .*120 A")
shot(1000, "shop_wide")
at(1010, function() mod.gfx.apply{ aspect = "4:3" } end)
shot(1100, "shop_4x3")
at(1110, function() mod.gfx.apply{ aspect = "fill" } end)
tap(1150, "X")                                             -- Button 4: retail's low camera (mod modes hang off it)
shot(1195, "camera_low")
local t = 1200
for i, v in ipairs{ { -45, 16 }, { -90, 18 } } do
  at(t, function() cam.set_mode("free"); free_camera.yaw = math.rad(v[1]); free_camera.dist = v[2]; free_camera.dirty = true end)
  shot(t + 70, "free_camera_" .. i)
  t = t + 80
end
for i, y in ipairs{ 0, -0.8 } do
  at(t, function() cam.set_mode("first_person"); first_person.yaw = y; first_person.pitch = 0 end)
  shot(t + 60, "first_person_" .. i)
  t = t + 70
end
at(t, function() cam.set_mode(nil) end)
at(t + 10, function() wardrobe.cfg.set("preset", "Midnight"); wardrobe.apply() end)
shot(t + 120, "camera_low_midnight")
t = t + 130
at(t, function() cam.set_mode(nil) end)
at(t + 30, function() ffi.cast("void(__cdecl*)(void)", 0x45337b)() end)     -- ESC: the pause list
tap(t + 70, "D .*8 D .*8 A .*40 U .*10 R")
shot(t + 190, "page_display")
tap(t + 200, "R .*20 R")
shot(t + 270, "page_wardrobe")
tap(t + 280, "L")
shot(t + 340, "page_first_person")
