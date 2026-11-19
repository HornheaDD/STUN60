-- S.T.U.N. Runner 60fps unlock (experimental) + on-screen drawn-FPS counter.
-- The GSP waits for a minimum number of screen refreshes per frame, stored at
-- bit address FFF77E80 (game default 3 = 20fps). Forcing it to 1 allows 60fps.
-- Side effect: game logic is tied to drawn frames, so gameplay runs up to 3x fast.
-- Real gameplay at stock clocks is render-bound (~1.5-2.1 refreshes of GSP drawing
-- per frame plus waiting for the 68010's display list), so expect ~18-30fps here
-- unless the gsp/maincpu are also overclocked via Tab > Slider Controls.
-- Patches RAM only; ROM files are not modified.
-- Set MIN_REFRESHES = 0 to leave the game's cap alone (counter only).
local MIN_REFRESHES = 1
local gsp = manager.machine.devices[":mainpcb:gsp"].spaces["program"]
local scr = manager.machine.screens[":mainpcb:screen"]
-- Count real game frames: the GSP frame loop writes the elapsed-refresh count
-- to FFF716B0 once per drawn frame (HUD-only changes are not counted).
local frames, n, shown, elapsed = 0, 0, "--", 0
fps_tap = gsp:install_write_tap(0xFFF716B0, 0xFFF716BF, "fpscount", function(off, data)
  frames = frames + 1
  elapsed = data & 0xff
end)
emu.register_frame_done(function()
  if MIN_REFRESHES > 0 then gsp:write_u16(0xFFF77E80, MIN_REFRESHES) end
  n = n + 1
  if n % 60 == 0 then shown = tostring(frames); frames = 0 end
  scr:draw_box(2, 2, 92, 14, 0xc0000000, 0xffffff00)
  scr:draw_text(5, 4, "Drawn FPS: " .. shown, 0xff000000)
end)
