local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local frame = 0
local END = tonumber(os.getenv("END") or "5000")
local out = io.open(os.getenv("SNDLOG"), "w")
local jc = manager.machine.devices[":mainpcb:jsa:cpu"]
local js = jc.spaces["program"]
local ymaddr = 0
local cnt = {}
local function inst()
  J1 = js:install_read_tap(0x2800,0x29ff,"cmd",function(o,d) if (o&6)==2 then out:write(string.format("%d CMD %02X\n",frame,d&0xff)) end end)
  J2 = js:install_write_tap(0x2a00,0x2bff,"wr",function(o,d) local f=o&6
     if f==6 then out:write(string.format("%d MIX %02X\n",frame,d&0xff)) elseif f==0 then cnt.oki=(cnt.oki or 0)+1 elseif f==2 then out:write(string.format("%d RSP %02X\n",frame,d&0xff)) end end)
  J3 = js:install_write_tap(0x2000,0x2001,"ym",function(o,d) if o==0x2000 then ymaddr=d&0xff else
      if ymaddr==8 then out:write(string.format("%d KEY %02X\n",frame,d&0xff)) end
      cnt.ym=(cnt.ym or 0)+1 end end)
end
emu.register_frame_done(function()
  frame = frame + 1
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if t == 200 then inst() end
  if t%60==0 then out:write(string.format("%d SEC ym %d oki %d\n",t,cnt.ym or 0,cnt.oki or 0)); cnt={} end
  if frame == END then out:close(); manager.machine:exit() end
end)
if os.getenv("WITHSCRIPT") then dofile(os.getenv("HOME") .. "/mame/scripts/stunrun-interp60.lua") end
