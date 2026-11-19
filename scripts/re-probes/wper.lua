local tps = emu.osd_ticks_per_second(); local prev; local n=0
local f = io.open(os.getenv("WLOG"), "w")
emu.register_frame_done(function() n=n+1; local w=emu.osd_ticks()
  if prev and n>1380 and n<=1440 then f:write(string.format("%.1f ", (w-prev)/tps*1000)) end; prev=w end)
dofile(os.getenv("HOME") .. "/mame/scripts/stunrun-interp60.lua")
