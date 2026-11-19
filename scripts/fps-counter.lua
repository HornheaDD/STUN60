-- On-screen counter for MAME games (first screen): counts how many genuinely new images
-- the game draws per second (screen refresh is always ~60 Hz).
local scr
for _, s in pairs(manager.machine.screens) do scr = s; break end
local last, n, changes, shown = nil, 0, 0, "--"
emu.register_frame_done(function()
  local px = scr:pixels()
  if px ~= last then changes = changes + 1 end
  last = px; n = n + 1
  if n % 60 == 0 then shown = tostring(changes); changes = 0 end
  scr:draw_box(2, 2, 92, 14, 0xc0000000, 0xffffff00)
  scr:draw_text(5, 4, "Drawn FPS: " .. shown, 0xff000000)
end)
