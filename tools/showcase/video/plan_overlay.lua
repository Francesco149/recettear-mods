-- the developer overlay in real time (its fps line is the display's): no frame dump — the desktop is recorded while
-- this runs.  Run (loader repo): tools/win_steam.py TAG --mods display,first-person,free-camera,unlock-menu,wardrobe,dashboard,video
--   --grab --secs 90 --cfg display=borderless vsync=on fps=auto aspect=fill fullbg=cover
--   --modcfg free-camera.help=off first-person.help=off video.plan=plan_overlay
-- Also takes the loader README's picture (overlay + dashboard, Recette in the Midnight preset).
local t = tap(260, "A .*120 A .*120 A")
t = t + 380
tap(t - 120, "X")                                            -- the game's low camera
at(t, function() mod.log("showcase: overlay on") end)
at(t + 60, function() mod.ui.show(true) end)
tap(t + 150, "L*40 .*40 R*40 .*40 U*30 .*30 D*30")
at(t + 480, function() wardrobe.cfg.set("preset", "Midnight"); wardrobe.apply() end)
at(t + 600, function() mod.log("showcase: shot readme_overlay", mod.screen.shot(mod.dir .. "readme_overlay.bmp")) end)
at(t + 660, function() mod.ui.show(false) end)
finish(t + 720)
