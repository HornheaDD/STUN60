local m = manager.machine.devices[":mainpcb:maincpu"]
local ms = m.spaces["program"]
local MPC = m.state["PC"]
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local frame, rec, nj = 0, nil, 0
local out = io.open("pcs.txt","w")
emu.register_frame_done(function()
  frame = frame + 1
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if frame == 2390 then
    t1 = ms:install_write_tap(0x818000, 0x81807F, "ctl", function(o,d)
      if o == 0x818006 or o == 0x818016 then nj = nj + 1; rec = true; out:write(string.format("JOB %d frame %d\n", nj, frame)) 
      elseif o == 0x81801A and rec and MPC.value ~= 0x02E464 and MPC.value ~= 0x02E414 then rec = false end end)
    t2 = ms:install_write_tap(0x808000, 0x80BFFF, "dat", function(o,d)
      if rec then out:write(string.format("%06X %04X %06X\n", o, d & 0xffff, MPC.value)) end end)
  end
  if nj >= 6 then out:close(); manager.machine:exit() end
end)
