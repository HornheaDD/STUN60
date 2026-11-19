local gsp = manager.machine.devices[":mainpcb:gsp"].spaces["program"]
local scr = manager.machine.screens[":mainpcb:screen"]
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local MIN = tonumber(os.getenv("MINR") or "1")
local frame = 0
local out = io.open(os.getenv("OUT") or "tl.txt","w")
local FP = scr.frame_period
local function T() return manager.machine.time:as_double()/FP end
local function log(tag) if frame >= 1200 then out:write(string.format("%s %.3f\n", tag, T())) end end
t1 = gsp:install_write_tap(0xFFF716B0, 0xFFF716BF, "s", function() log("S") end)
t2 = gsp:install_write_tap(0xFFF77F30, 0xFFF77F4F, "l", function(o,d) if o==0xFFF77F30 then log("L") end end)
t3 = gsp:install_write_tap(0xFFF71670, 0xFFF7168F, "f", function(o,d) if o==0xFFF71670 then log(d~=0 and "D" or "F") end end)
emu.register_frame_done(function()
  frame = frame + 1
  if MIN > 0 then gsp:write_u16(0xFFF77E80, MIN) end
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if frame % 600 == 0 then out:flush(); print("frame", frame, T()) end
  if frame == 5460 then out:close(); manager.machine:exit() end
end)
