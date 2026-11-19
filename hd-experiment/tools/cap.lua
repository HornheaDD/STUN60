local gspd = manager.machine.devices[":mainpcb:gsp"]
local gsp = gspd.spaces["program"]
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local TF = tonumber(os.getenv("TF") or "2400")
local TAG = os.getenv("TAG") or "c"
local frame, st, busy = 0, 0, false
local PC = gspd.state["PC"]
local function dump(a5)
  local out = io.open(TAG..".bin","wb"); local t = {}
  for a = 0xFFF00000, 0xFFFFFFF0, 0x10 do
    local w = gsp:read_u16(a); t[#t+1] = string.char(w & 0xff, w >> 8)
  end
  out:write(table.concat(t)); out:close()
  local f = io.open(TAG..".txt","w"); f:write(string.format("%X\n", a5)); f:close()
end
tr = gsp:install_read_tap(0xFFF80000, 0xFFFFFFFF, "r", function(o,d2,m)
  if busy or st ~= 0 or frame < TF then return end
  if PC.value == 0xFFF46FA0 and (d2 & 0xF000) == 0x7000 then busy = true; dump(o); busy = false; st = 1 end end)
td = gsp:install_write_tap(0xFFF71670, 0xFFF7168F, "f", function(o,d2)
  if o == 0xFFF71670 and d2 ~= 0 and st == 1 then st = 2 end end)
local k = 0
emu.register_frame_done(function()
  frame = frame + 1
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if st == 2 then k = k + 1; manager.machine.video:snapshot()
    if k == 3 then manager.machine:exit() end end
end)
