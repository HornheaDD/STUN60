local MIN = tonumber(os.getenv("MINR") or "0")
local gsp = manager.machine.devices[":mainpcb:gsp"].spaces["program"]
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local frame, nfr, hist, tot = 0, 0, {}, {}
tap = gsp:install_write_tap(0xFFF716B0, 0xFFF716BF, "fl", function(off, data, mask)
  nfr = nfr + 1
  local e = data & 0xff; hist[e] = (hist[e] or 0) + 1
end)
emu.register_frame_done(function()
  frame = frame + 1
  if MIN > 0 then gsp:write_u16(0xFFF77E80, MIN) end
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if frame % 300 == 0 and frame >= 1200 then
    local s = ""
    for k=0,12 do if hist[k] then s = s .. k .. ":" .. hist[k] .. " " end end
    print(string.format("t=%3ds fps=%4.1f elapsed{%s}", frame//60, nfr/5, s))
    nfr, hist = 0, {}
  elseif frame % 300 == 0 then nfr, hist = 0, {} end
end)
