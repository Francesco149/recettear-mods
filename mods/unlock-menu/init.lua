-- unlock-menu — the full title menu whatever the saves hold (none at all included).  Spec: docs/mods/unlock-menu.md.
--
-- Rows: retail's build 0x49a43d lists rows from the unlock scan 0x49a324 (bit0 = a cleared save, bit1 = one holding
-- a clear item) plus LOAD GAME when some bank is occupied.  Its scan call returns 3 here, and after each build the
-- list is set to all 8 rows (5 4 6 1 7 8 2 3) with retail's own 8-row layout (0x5d1bb4 = 27, 0x5d1bb8 = -36).
--
-- NEW GAME + / SURVIVAL: retail's picker 0x49b4f4 lists only cleared banks (GAME_MODE 3 + clear item); here it lists
-- all 100 slots.  The confirm (inside title logic 0x49a59e) wants the slot occupied (+8 > 0), and for SURVIVAL also
-- GAME_MODE 3 (+0x2dd64) and the clear-item byte 0x96432f4[bank].  On the tick the confirm button is pressed, those
-- fields of the chosen slot are set in memory before the logic call and put back right after it (the call copies
-- the slot into the work bank, 0x490259), so the save file never sees them.  An empty slot holds retail's own
-- blank bank (0x49001c, written at boot for every unused slot) → a fresh NG+ / Survival with no source save.
local mem, sym = mod.mem, mod.sym

if mod.config.get("mode") == "vanilla" then mod.log("mode = vanilla: off") return end
local scan, build, logic, picker = sym.va("title_unlock_mask"), sym.va("title_build"), sym.va("title_logic"),
  sym.va("title_picker_filter")
if not (scan and build and logic and picker) then mod.log("title symbols unverified on this exe — off") return end

local CODES, NROWS, CURSOR = 0x9643358, 0x9643510, 0x9643540   -- title row codes [8], count, cursor row
local LAYOUT_A, LAYOUT_B = 0x5d1bb4, 0x5d1bb8                   -- row pitch / top offset (retail's 8-row values)
local SUB, START, PCUR = 0x9643524, 0x964351c, 0x9643540 - 0x10 -- open submenu, start counter, picker cursor 0x9643530
local LIST, COUNT = 0x9643380, 0x5d1bbc                         -- picker bank list [100], count
local BANKS, STRIDE = 0x56e6280, 0x2dfc8                         -- save arena banks (save.dat image)
local OCC, MODE = 8, 0x2dd64                                     -- bank +8 occupied (> 0), +0x2dd64 GAME_MODE
local CLEARB = 0x96432f4                                         -- clear-item byte per bank (scan output, not saved)
local PRESSED, A = 0x73dddd4, 0x10                               -- this tick's pressed-button mask; confirm bit
local ROWS = { 5, 4, 6, 1, 7, 8, 2, 3 }

local function row_code() return mem.read_i32(CODES + 4 * mem.read_i32(CURSOR)) end

-- rows: the scan's call in the build → 3; after every build → all 8 rows
for _, site in ipairs(mod.hook.calls_to(scan)) do
  if sym.name_at(site) == "title_build" then mod.hook.callsite(site, { post = function(c) c.eax = 3 end }) end
end
for _, site in ipairs(mod.hook.calls_to(build)) do
  mod.hook.callsite(site, { post = function()
    local had_load = false
    for i = 0, mem.read_i32(NROWS) - 1 do if mem.read_i32(CODES + 4 * i) == 1 then had_load = true end end
    for i, c in ipairs(ROWS) do mem.write_i32(CODES + 4 * (i - 1), c) end
    mem.write_i32(NROWS, 8)
    mem.write_f32(LAYOUT_A, 27.0); mem.write_f32(LAYOUT_B, -36.0)
    if not had_load then mem.write_i32(CURSOR, 0) end   -- retail parks the cursor on LOAD only when it exists
  end })
end

-- NG+ / Survival picker: every slot
for _, site in ipairs(mod.hook.calls_to(picker)) do
  mod.hook.callsite(site, { post = function()
    local code = row_code()
    if code ~= 4 and code ~= 6 then return end
    for b = 0, 99 do mem.write_i32(LIST + 4 * b, b) end
    mem.write_i32(COUNT, 100)
  end })
end

-- the confirm: make the chosen slot pass retail's checks for the length of one title-logic call
local saved
for _, site in ipairs(mod.hook.calls_to(logic)) do
  mod.hook.callsite(site, {
    pre = function()
      saved = nil
      if mem.read_i32(SUB) ~= 1 or mem.read_i32(START) ~= 0 then return end
      if bit.band(mem.read_i32(PRESSED), A) == 0 then return end
      local code = row_code()
      if code ~= 4 and code ~= 6 then return end
      local pc = mem.read_i32(PCUR)
      if pc < 0 or pc >= mem.read_i32(COUNT) then return end
      local b = mem.read_i32(LIST + 4 * pc)
      if b < 0 or b > 99 then return end
      local base = BANKS + b * STRIDE
      saved = { base = base, b = b, occ = mem.read_i32(base + OCC), mode = mem.read_i32(base + MODE),
                clr = mem.read_u8(CLEARB + b) }
      if saved.occ <= 0 then mem.write_i32(base + OCC, 1) end
      if code == 6 then mem.write_i32(base + MODE, 3); mem.write_u8(CLEARB + b, 1) end
      mod.log(("%s from slot %03d%s"):format(code == 4 and "NEW GAME +" or "SURVIVAL", b + 1,
        saved.occ <= 0 and " (empty: fresh start)" or ""))
    end,
    post = function()
      if not saved then return end
      mem.write_i32(saved.base + OCC, saved.occ)
      mem.write_i32(saved.base + MODE, saved.mode)
      mem.write_u8(CLEARB + saved.b, saved.clr)
      saved = nil
    end,
  })
end
mod.log("title unlock armed: 8 rows; NG+ / Survival from any slot (empty = fresh)")
