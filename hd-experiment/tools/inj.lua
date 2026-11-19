-- Inject extra ADSP renders with an interpolated camera (test harness, stock clocks: stalls the 68010 meanwhile)
local m = manager.machine.devices[":mainpcb:maincpu"]
local ms = m.spaces["program"]
local MPC = m.state["PC"]
local gspd = manager.machine.devices[":mainpcb:gsp"]
local gsp = gspd.spaces["program"]
local GPC = gspd.state["PC"]
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local TF = tonumber(os.getenv("TF") or "2400")
local TS = os.getenv("TS") or "0,0.5,1"          -- interpolation factors to test, one injection each
local TAG = os.getenv("TAG") or "inj"
local ts = {} for x in TS:gmatch("[^,]+") do ts[#ts+1] = tonumber(x) end
local log = io.open(TAG..".log","w")
local function L(s) log:write(s.."\n"); log:flush() end
local frame = 0
local rec, jobs = nil, {}       -- jobs[i] = {list of {addr,data}}
local bank = 0
local injecting, state, ti = false, "idle", 0
local nlist = 0
local function s16(v) v = v & 0xffff; if v >= 0x8000 then return v - 0x10000 end return v end
-- recording -----------------------------------------------------------
local function on_ctl(o, d)
  if injecting then return end
  if o == 0x818006 or o == 0x818016 then
    bank = (o == 0x818016) and 1 or 0
    rec = {}  -- a job upload follows the bank toggle
  elseif o == 0x81801A and rec and MPC.value ~= 0x02E464 and MPC.value ~= 0x02E414 then
    jobs[#jobs+1] = rec; rec = nil
    L(string.format("job %d recorded (%d writes) frame %d", #jobs, #jobs[#jobs], frame))
  end
end
local function on_data(o, d)
  if injecting or not rec then return end
  rec[#rec+1] = {o, d & 0xffff}
end
-- camera interpolation --------------------------------------------------
local function camvals(job)
  local c = {}
  for _,w in ipairs(job) do if w[1] >= 0x80BFCC and w[1] <= 0x80BFFA then c[w[1]] = w[2] end end
  return c
end
local function lerp_job(A, B, t)
  local ca, cb = camvals(A), camvals(B)
  local out = {}
  for _,w in ipairs(A) do
    local o, d = w[1], w[2]
    if o >= 0x80BFD2 and o <= 0x80BFDC and ((o - 0x80BFD2) % 4) == 0 and cb[o] and cb[o+2] then
      -- 32-bit position long (hi word at o, lo at o+2)
      local va = (ca[o] << 16) | ca[o+2]; if va >= 0x80000000 then va = va - 0x100000000 end
      local vb = (cb[o] << 16) | cb[o+2]; if vb >= 0x80000000 then vb = vb - 0x100000000 end
      local v = math.floor(va + (vb - va) * t + 0.5) & 0xffffffff
      out[#out+1] = {o, v >> 16}; LONGLO = v & 0xffff
    elseif o >= 0x80BFD4 and o <= 0x80BFDE and ((o - 0x80BFD2) % 4) == 2 and LONGLO then
      out[#out+1] = {o, LONGLO}; LONGLO = nil
    elseif o >= 0x80BFEA and o <= 0x80BFFA and cb[o] then
      local v = math.floor(s16(ca[o]) + (s16(cb[o]) - s16(ca[o])) * t + 0.5)
      out[#out+1] = {o, v & 0xffff}
    else
      out[#out+1] = {o, d}
    end
  end
  return out
end
-- injection -------------------------------------------------------------
local function start_inject(t)
  local A, B = jobs[#jobs-1], jobs[#jobs]
  local job = lerp_job(A, B, t)
  injecting = true
  ms:write_u16(0xFF9BB4, 0)                 -- keep the 68010 waiting
  ms:write_u16(0x81800A, 0)                 -- /BR: halt ADSP
  ms:write_u16(0x818008, 0)
  local b = bank                            -- 68k currently reads bank b; ADSP writes b^1 (job just done)
  ms:write_u16(b == 1 and 0x818006 or 0x818016, 0)   -- 68k bank = b^1, so ADSP writes bank b (already copied)
  for _,w in ipairs(job) do ms:write_u16(w[1], w[2]) end
  ms:write_u16(0x818018, 0)
  ms:write_u16(0x81801A, 0)                 -- release
  L(string.format("inject t=%.2f (jobs %d->%d) frame %d bank %d", t, #jobs-1, #jobs, frame, b))
  state = "running"
end
local function on_done(o, d)
  if (not injecting) and state == "idle" and frame >= TF and #jobs >= 2 and ti < #ts and (d & 0xffff) == 1 then
    state = "pending"; L("real job done, holding 68010, frame "..frame); return 0
  end
  if injecting and state == "running" and (d & 0xffff) == 1 then
    state = "done"; L("inject done frame "..frame)
    return 0                                -- keep 68010 waiting until we read the output
  end
end
local function read_output(t)
  local n = ms:read_u16(0x810000)
  local words = {}
  for i = 1, n do words[i] = ms:read_u16(0x810000 + 2*i) end
  local f = io.open(string.format("%s_t%.2f.words", TAG, t), "w")
  f:write("7000\n"); for _,w in ipairs(words) do f:write(string.format("%04X\n", w)) end; f:close()
  L(string.format("read %d words, last %04X", n, words[n] or 0))
end
-- GSP list dumps for comparison -------------------------------------------
local busy = false
tr = gsp:install_read_tap(0xFFF80000, 0xFFFFFFFF, "r", function(o,d2)
  if busy or frame < TF - 20 then return end
  if GPC.value == 0xFFF46FA0 and (d2 & 0xF000) == 0x7000 then
    busy = true; nlist = nlist + 1
    local t = {}
    local base = o + 16; local cnt = gsp:read_u16(base)
    local a3 = base + cnt*16
    while gsp:read_u16(a3) ~= 0xFFFF do a3 = a3 + 16 end
    local f = io.open(string.format("%s_list%02d.words", TAG, nlist), "w"); f:write("7000\n")
    for a = base, a3, 16 do f:write(string.format("%04X\n", gsp:read_u16(a))) end; f:close()
    L(string.format("gsp list %d frame %d", nlist, frame))
    busy = false
  end end)
emu.register_frame_done(function()
  frame = frame + 1
  local t = frame
  local c=(t>=600 and t<620) or (t>=640 and t<660); coin:set_value(c and 1 or 0); coin2:set_value(c and 1 or 0)
  start:set_value(((t>=700 and t<720) or (t>=900 and t<920)) and 1 or 0)
  b1:set_value(t>=1000 and ((t//30)%2) or 0)
  if frame == TF - 60 then
    t1 = ms:install_write_tap(0x818000, 0x81807F, "ctl", on_ctl)
    t2 = ms:install_write_tap(0x808000, 0x80BFFF, "dat", on_data)
    t3 = ms:install_write_tap(0xFF9BB4, 0xFF9BB5, "done", on_done)
  end
  if frame >= TF and #jobs >= 2 then
    if state == "pending" then
      ti = ti + 1; start_inject(ts[ti])
    elseif state == "done" then
      ms:write_u16(bank == 1 and 0x818016 or 0x818006, 0)   -- restore 68k bank b -> shows our output
      state = "readable"
    elseif state == "readable" then
      read_output(ts[ti]); injecting = false; state = "idle"
      ms:write_u16(0xFF9BB4, 1)              -- let the 68010 continue
    end
  end
  if frame == TF + 120 then log:close(); manager.machine:exit() end
end)
