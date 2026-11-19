local n=0
emu.register_frame_done(function() n=n+1
  if n==1500 then
    local d=manager.machine.debugger
    d:command("dasm " .. os.getenv("HOME") .. "/mame/scripts/re-probes/col/gsp_poly.asm,FFF44BF0,1800,1,:mainpcb:gsp")
    d:command("dasm " .. os.getenv("HOME") .. "/mame/scripts/re-probes/col/gsp_alt.asm,FFF48FC0,800,1,:mainpcb:gsp")
  end
  if n==1510 then manager.machine:exit() end end)
