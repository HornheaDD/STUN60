-- headless driver: scripted coin/start/fire, then load the live script
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local frame = 0
local SNAP0 = tonumber(os.getenv("SNAP0") or "0")
local END = tonumber(os.getenv("END") or "3000")
emu.register_frame_done(function()
  frame = frame + 1
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if SNAP0 > 0 and frame >= SNAP0 and frame < SNAP0 + 24 then manager.machine.video:snapshot() end
  if frame == END then manager.machine:exit() end
end)

