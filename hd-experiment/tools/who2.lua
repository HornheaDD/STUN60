local gsp = manager.machine.devices[":mainpcb:gsp"].spaces["program"]
local m = manager.machine.devices[":mainpcb:maincpu"]
local MPC = m.state["PC"]
local gpc = manager.machine.devices[":mainpcb:gsp"].state["PC"]
local adpc = manager.machine.devices[":mainpcb:adsp"].state["PC"]
local frame, cnt, hist = 0, 0, {}
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
tw = gsp:install_write_tap(0xFFFA0000, 0xFFFDFFFF, "w", function(o,d)
  if frame >= 2400 and frame < 2406 then
    local k = string.format("m68 %06X gsp %08X", MPC.value, gpc.value); hist[k] = (hist[k] or 0) + 1 end end)
emu.register_frame_done(function()
  frame = frame + 1
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if frame == 2406 then
    local ks = {} for k,v in pairs(hist) do ks[#ks+1] = {k,v} end
    table.sort(ks, function(a,b) return a[2] > b[2] end)
    for i=1,math.min(15,#ks) do print(ks[i][2], ks[i][1]) end
    manager.machine:exit()
  end
end)
