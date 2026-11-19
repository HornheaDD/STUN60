local m = manager.machine.devices[":mainpcb:maincpu"]
local ms = m.spaces["program"]
local MPC = m.state["PC"]
local frame, hist = 0, {}
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local out = io.open("w68.txt","w")
emu.register_frame_done(function()
  frame = frame + 1
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if frame == 2399 then
    tw = ms:install_write_tap(0x800000, 0x81FFFF, "w", function(o,d,mk)
      if frame >= 2400 and frame < 2403 then out:write(string.format("%d W %06X %04X pc %06X\n", frame, o, d & 0xffff, MPC.value)) end end)
    tr = ms:install_read_tap(0x800000, 0x81FFFF, "r", function(o,d,mk)
      if frame >= 2400 and frame < 2403 then out:write(string.format("%d R %06X %04X pc %06X\n", frame, o, d & 0xffff, MPC.value)) end end)
  end
  if frame == 2403 then out:close(); manager.machine:exit() end
end)
