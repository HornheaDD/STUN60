local gsp = manager.machine.devices[":mainpcb:gsp"].spaces["program"]
local m = manager.machine.devices[":mainpcb:maincpu"]
local ms = m.spaces["program"]
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local MIN = tonumber(os.getenv("MINR") or "0")
local frame, nt = 0, 0
local out = io.open(os.getenv("OUT") or "dump.bin","wb")
local idx = io.open((os.getenv("OUT") or "dump.bin")..".idx","w")
t1 = ms:install_write_tap(0xFFDB48, 0xFFDB49, "w", function(o,d)
  if d ~= 0 and frame >= 1800 and nt < 200 then
    nt = nt + 1
    out:write(ms:read_range(0xFF0000, 0xFFFFFF, 8))
    idx:write(frame, "\n")
  end end)
emu.register_frame_done(function()
  frame = frame + 1
  if MIN > 0 then gsp:write_u16(0xFFF77E80, MIN) end
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if frame == 1800 or frame == 2400 then manager.machine.video:snapshot() end
  if nt >= 200 then out:close(); idx:close(); manager.machine:exit() end
end)
