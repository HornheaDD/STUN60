local tps = emu.osd_ticks_per_second(); local prev, sec, mx, late, n = nil, nil, 0, 0, 0
local f = io.open(os.getenv("WLOG"), "w")
emu.register_frame_done(function() n = n + 1; local w = emu.osd_ticks()
  if prev then local dt=(w-prev)/tps; if dt>mx then mx=dt end; if dt>0.025 then late=late+1 end end; prev=w; sec=sec or w
  if n % 60 == 0 then f:write(string.format("%d wall %.3f max %.0f ms late %d\n", n, (w-sec)/tps, mx*1000, late)); f:flush(); sec=w; mx=0; late=0 end end)
