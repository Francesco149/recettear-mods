# Showcase video recipe

How the first showcase (2026-11-27, 66 s) was made, so the next one (other mods) matches it. Tools: `video/` (capture
plan), `showcase.py` (edit), the loader's `tools/win_steam.py` (runs on cutestation). Outputs in `~/Videos/showcase/`.

## The bar (owner, 2026-11-27)

- **No text on black.** Every caption lies over gameplay: in idle parts of the picture, or over a dimmed last clip.
- Real game footage at 1920×1080, 60 fps, one feature per segment, the feature visibly *happening* (a setting switched
  live, a camera moving, presets changing), not a still.
- Music: the game's own shop theme (the user's `bgm/open.wav`, looped by restarting it, as the game does). Owner's
  call for an un-monetised fan video; never commit it.
- Three files: `showcase_1080p60.mp4` (YouTube), `showcase_discord.mp4` (under 20 MB), `showcase_readme.mp4`
  (**under 10 MB**: GitHub’s README upload limit; 720p60 — owner 2026-11-27: 60 fps is worth the bitrate; fine texture is a little softer than at 30).
- High refresh is shown by the slow-motion wipe from the owner's camera recording (`hirefresh.py` `SECTIONS[1]`); the
  full comparison stays its own video.

## 1. Storyboard

One line per segment: what the viewer sees change, 5–9 s each, about a minute in total (the music is 62 s; past
~70 s the loop seam shows up mid-video). Order used: what this is (title screen) → display features → cameras →
customisation → the loader / API → end plate.

## 2. Capture (`video/plan.lua`)

A tool mod scripts one run of the real game by tick: `tap(t, "U .*24 A")`, `at(t, fn)`, `anim(t0, t1, fn(k, s))`,
`rec(t0, t1, "name")`, `finish(t)`. A clip = one BMP per tick, encoded to near-lossless mkv on the Windows box.

    # preview: every 6th tick, ~5 min a round — iterate on this, look at contact sheets
    tools/win_steam.py vid-pN --mods display,first-person,free-camera,unlock-menu,wardrobe,dashboard,video \
      --encode 10 --secs 500 --cfg display=borderless vsync=on fps=60 aspect=fill fullbg=cover \
      --modcfg free-camera.help=off first-person.help=off display.fps=60 video.step=6
    # final: every tick (~10 min, ~25 GB of BMPs on C: while it runs)
    … --encode 60 --secs 1800 …            (no video.step)
    # sheet: ffmpeg -i clip.mkv -vf "select='not(mod(n,K))',scale=480:-1,tile=4x4" -frames:v 1 sheet.jpg

Look at a sheet of **every** clip after every plan change; four preview rounds were needed the first time.

Things that cost a round:
- `display.fps=60` in `--modcfg`: the display mod's saved default (Auto) overrides the loader cfg, and with
  interpolation on, frames go missing from the dump.
- A tick with a device Reset (`mod.gfx.apply{aspect=…}`) has no Present: `--encode` fills the gap with the previous
  frame.
- Clip names must not be prefixes of each other (`wardrobe` / `wardrobe_page` → one swallowed the other).
- Mod camera modes hang off the game's low camera: `tap(t, "X")` once before `cam.set_mode("free" | "first_person")`.
- Menu taps need ≥ 8 idle ticks between presses (`U .*8 U`); with 5 some are dropped.
- Options pages from the pause list: `D .*8 D .*8 A .*40 U .*10 R` = Display Settings; one more `R` each: First
  Person, Wardrobe. First `D` from the header = row 1.
- Free camera: negative yaw and low heights put the roof beams across the view; yaw 0…0.95, dist 11…22, height 8…20
  are clean. The game's low camera follows Recette (after a walk the framing differs).
- First person: script `first_person.yaw / pitch` per tick and hold `U` to walk; check where she ends up (walls).
- Don't change a device row (Aspect Ratio, Display Mode) inside the pause menu on camera: the pause background
  goes black (open bug, loader HANDOFF). Do it in the shop with `mod.gfx.apply`.
- Anything that must run in real time (the dev overlay's fps line reads ~35 while frames are dumped): record it off
  the desktop instead — `video.plan=plan_overlay`, `--grab 42 --alttab 5` with `fps=auto` (`--alttab` puts the game
  in front of the owner's windows). Cut the stretch you need into `CLIPS_DIR/overlay_rt.mkv`, **delete the grab** (its
  first seconds show the desktop), mask what is not the game (a desktop clock sat top-right: `drawbox`).
- The run uses the owner's screen for its length and the Steam copy's newest save (a Day-2 shop). A different scene
  = a different save: ask, or craft one (never ask the owner to reconstruct state).

## 3. Edit (`showcase.py`)

    tools/showcase/showcase.py CLIPS_DIR ~/Videos/PLIB2505.MOV /mnt/ephemeral/openrecet/staged_retail/bgm/open.wav \
      -o SCRATCH --preview            # then without --preview and -o: the three files in ~/Videos/showcase/
    … --only 08                       # one segment        … --copies   # only the two small encodes

`build()` is the storyboard: one `Seg` per segment (clip, cut points, captions). Keep the look:
- **Plates** (Pillow, `chip` / `pill` / `note` / `headline`): dark warm plate `INK` at ~80 % with a soft shadow, amber
  `AMBER` bar; kicker `MOD · <id>` in letter-spaced amber Roboto Bold 21, title Roboto Black 50, one or two detail
  lines Roboto Medium 27 in `CREAM`. Pills for states (`4:3 · the game as shipped` → `16:9 · switched live`), cream
  for the stock state, amber for ours.
- **Motion**: plates fade in 0.35 s and slide 44 px from their side, fade out 0.3 s; segments cross-fade 0.4 s; the
  video fades in / out, the music fades out over its last 3 s.
- **Placement**: where the picture is idle — top-right in the shop (the void beside the room), top-right over the
  blurred pause background, right-middle on the title screen (below the logo, beside the menu), bottom-left on camera
  footage. Never over the thing being shown, the game's HUD corners, or the overlay's windows.
- **Small subjects** get a 2× nearest-neighbour inset with an amber border (Recette in the wardrobe segment:
  `--recette X Y` = her centre in that clip) and a pill under it naming the state.
- **Opening** = the headline plate over the first clip; **end** = a centred headline (name, repo URL, licence + "you
  need your own copy of the game") over the last clip, dimmed and slightly blurred.
- Copy: what it does for the player, in the game's terms, two short lines at most; no claims the footage does not show.

Check: a contact sheet of the whole preview (`fps=1/2.5,scale=480:-1,tile=6x5`) and a full-size still per segment
(captions clear of the action? cut points on the right frame?), then the stream durations (video = audio) and
`volumedetect`. Nobody but the owner can judge pacing, feel and the music: hand it over as "not watched at speed".

## 4. Publish

- Stills for the READMEs come from the same captures (`readme_overlay.bmp`, crops of clip frames).
- `gh release upload TAG ~/Videos/showcase/showcase_readme.mp4` and link it from both READMEs; the inline player
  needs the owner to drag the under-10 MB file into the README editor on github.com (no API for that upload).
- The owner uploads the 1080p60 master to YouTube.
- Push / release only when asked.
