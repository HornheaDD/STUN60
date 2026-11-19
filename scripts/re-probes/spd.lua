local v = manager.machine.video
local fr = 0
local f = io.open("spd.txt","w")
emu.register_frame_done(function() fr = fr + 1
  if fr % 120 == 0 then local ok, s = pcall(function() return v.speed_percent end); f:write(fr, " ", tostring(s), "\n"); f:flush() end end)
dofile("live_test.lua")
