-- dump colour table FFF71D20 (1024 words) + GSP palette RAM shares at given frames (scripted play)
local gsp = manager.machine.devices[":mainpcb:gsp"].spaces["program"]
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local OUT = os.getenv("OUT")
local want = {[2400]=1,[3000]=1,[3600]=1,[2412]=1,[2424]=1,[2436]=1}
local frame = 0
local sh = manager.machine.memory.shares
local lo, hi = sh[":mainpcb:gsp_palram_lo"], sh[":mainpcb:gsp_palram_hi"]
emu.register_frame_done(function()
  frame = frame + 1
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if want[t] then
    local f = io.open(OUT.."/t"..t..".txt","w")
    local w = {}
    for i=0,1023 do w[#w+1] = string.format("%04X", gsp:read_u16(0xFFF71D20 + 16*i)) end
    f:write("TAB ", table.concat(w," "), "\n")
    if lo and hi then
      local a, b = {}, {}
      for i=0,1023 do a[#a+1]=string.format("%04X", lo:read_u16(2*i)); b[#b+1]=string.format("%04X", hi:read_u16(2*i)) end
      f:write("LO ", table.concat(a," "), "\nHI ", table.concat(b," "), "\n")
    else f:write("NOSHARE\n") end
    f:close()
  end
  if t == 3610 then manager.machine:exit() end
end)
