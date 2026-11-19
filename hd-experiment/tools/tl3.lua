local m = manager.machine.devices[":mainpcb:maincpu"]
local ms = m.spaces["program"]
local MPC = m.state["PC"]
local gsp = manager.machine.devices[":mainpcb:gsp"].spaces["program"]
local scr = manager.machine.screens[":mainpcb:screen"]
local FP = scr.frame_period
local function T() return manager.machine.time:as_double()/FP end
local frame = 0
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local out = io.open("tl3.txt","w")
local on = false
local last810 = -1
local function L(s) if on then out:write(string.format("%9.3f %s pc %06X\n", T(), s, MPC.value)) end end
emu.register_frame_done(function()
  frame = frame + 1
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if frame == 2390 then
    t1 = ms:install_write_tap(0x818000, 0x81807F, "c", function(o,d) L(string.format("W %06X %04X", o, d)) end)
    t2 = ms:install_read_tap(0x818000, 0x81807F, "cr", function(o,d) L(string.format("R %06X %04X", o, d)) end)
    t3 = ms:install_read_tap(0x838000, 0x83FFFF, "ir", function(o,d) L(string.format("R %06X %04X", o, d)) end)
    t4 = ms:install_write_tap(0x80BFCC, 0x80BFCD, "cam", function(o,d) L("CAMERA upload start") end)
    t5 = ms:install_read_tap(0x810000, 0x811FFF, "buf", function(o,d)
      if o == 0x810000 then L("copy ADSP buffer -> GSP start") end end)
    t6 = ms:install_write_tap(0xFFDB48, 0xFFDB49, "tick", function(o,d) L(string.format("tick flag FFDB48=%04X", d)) end)
    t7 = gsp:install_write_tap(0xFFF9FC00, 0xFFF9FC0F, "ma", function(o,d) L(string.format("GSP mailbox A=%04X", d)) end)
    t8 = gsp:install_write_tap(0xFFFCFC00, 0xFFFCFC0F, "mb", function(o,d) L(string.format("GSP mailbox B=%04X", d)) end)
    t9 = ms:install_write_tap(0x808000, 0x808003, "cmd", function(o,d) L(string.format("ADSP cmd word %06X=%04X", o, d)) end)
    t10 = ms:install_write_tap(0x80BFFE, 0x80BFFF, "bffe", function(o,d) L(string.format("W 80BFFE=%04X", d)) end)
  end
  if frame == 2400 then on = true end
  if frame == 2410 then out:close(); manager.machine:exit() end
end)
