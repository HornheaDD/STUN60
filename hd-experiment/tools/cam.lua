local gspd = manager.machine.devices[":mainpcb:gsp"]
local gsp = gspd.spaces["program"]
local ms = manager.machine.devices[":mainpcb:maincpu"].spaces["program"]
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local TF = tonumber(os.getenv("TF") or "2400")
local TAG = os.getenv("TAG") or "k"
local N = tonumber(os.getenv("N") or "12")
local MODE = os.getenv("MODE") or "none"
local frame, busy, n, tick = 0, false, 0, 0
local PC = gspd.state["PC"]
local cur, prev = {}, {}
local log = io.open(TAG..".log","w")
local function wr(name, t) local f = io.open(name,"wb"); f:write(table.concat(t)); f:close() end
local function dump(a5)
  n = n + 1
  local t = {}
  for a = 0xFFF80000, 0xFFFFFFF0, 0x10 do local w = gsp:read_u16(a); t[#t+1] = string.char(w & 0xff, w >> 8) end
  -- pad so dec.py offsets (from FFF00000) work
  wr(TAG.."_"..n..".bin", {string.rep("\0", 0x10000), table.concat(t)})
  local f = io.open(TAG.."_"..n..".txt","w"); f:write(string.format("%X\n%d\n", a5, frame)); f:close()
  log:write(string.format("list %d frame %d\n", n, frame))
end
tr = gsp:install_read_tap(0xFFF80000, 0xFFFFFFFF, "r", function(o,d2,m)
  if busy or frame < TF then return end
  if PC.value == 0xFFF46FA0 and (d2 & 0xF000) == 0x7000 then busy = true; dump(o); busy = false
    if n >= N then log:close(); manager.machine:exit() end end end)
emu.register_frame_done(function()
  frame = frame + 1
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if frame == TF - 30 then
    tc = ms:install_write_tap(0x80BFCC, 0x80BFFB, "cam", function(o, d, mk)
      if o == 0x80BFCC then tick = tick + 1; prev = cur; cur = {} end
      cur[o] = d
      local swap = (MODE == "prev" and frame >= TF and tick % 2 == 0 and prev[o] ~= nil)
      local camword = (o >= 0x80BFD2 and o <= 0x80BFDC) or (o >= 0x80BFEA and o <= 0x80BFFA)
      if swap and camword then
        if o == 0x80BFD2 then log:write(string.format("tick %d frame %d: camera replaced by previous\n", tick, frame)) end
        return prev[o]
      end
    end)
  end
end)
