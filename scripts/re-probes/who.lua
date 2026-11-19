local gsp = manager.machine.devices[":mainpcb:gsp"].spaces["program"]
local m = manager.machine.devices[":mainpcb:maincpu"]
local ms = m.spaces["program"]
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local frame = 0
local seen = {}
local taps = {}
local function inst()
for _,a in ipairs({0xFF956A, 0xFF9566, 0xFF8016, 0xFFDB38, 0xFF9582}) do
  taps[#taps+1] = ms:install_write_tap(a, a+1, "w"..a, function(o,d)
    hits = (hits or 0) + 1
    lasthit = frame
    if true then
      local k = string.format("%06X pc=%06X", a, m.state["PC"].value)
      seen[k] = (seen[k] or 0) + 1
    end end)
end
end
emu.register_frame_done(function()
  frame = frame + 1
  if frame == 1790 then inst() end
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if frame == 2100 then print("hits", hits, "last frame", lasthit); for k,v in pairs(seen) do print(k, v) end; manager.machine:exit() end
end)
