-- Extra ADSP renders with interpolated camera + objects. Test harness at stock clocks:
-- the 68010 is held in its "wait for ADSP" loop while the extra renders run.
local m = manager.machine.devices[":mainpcb:maincpu"]
local ms = m.spaces["program"]
local MPC = m.state["PC"]
local ad = manager.machine.devices[":mainpcb:adsp"].spaces["data"]
local P = manager.machine.ioport.ports
local function F(p,n) return P[p].fields[n] end
local coin, coin2 = F(":mainpcb:jsa:JSAII","Coin 1"), F(":mainpcb:IN0","Coin 1")
local start, b1 = F(":mainpcb:a80000","1 Player Start"), F(":mainpcb:a80000","P1 Button 1")
local TF = tonumber(os.getenv("TF") or "2400")
local NH = tonumber(os.getenv("NH") or "4")          -- number of held ticks (pairs) to process
local TS = {}; for x in (os.getenv("TS") or "0,0.3333,0.6667"):gmatch("[^,]+") do TS[#TS+1] = tonumber(x) end
local TAG = os.getenv("TAG") or "i2"
local log = io.open(TAG..".log","w")
local function L(s) log:write(s.."\n"); log:flush() end
local frame, rec, jobs, bank = 0, nil, {}, 0
local injecting, state, ti, nh, snap = false, "idle", 0, 0, nil
local POS = {[0x02E342]=1,[0x02E34C]=1,[0x02E356]=1,[0x02E24A]=1,[0x02E250]=1,[0x02E256]=1,
             [0x02E16C]=1,[0x02E176]=1,[0x02E180]=1,[0x02DED6]=1,[0x02DEE0]=1,[0x02DEEA]=1}
local MAT = {[0x022DE0]=1,[0x022DE2]=1,[0x022DE4]=1,[0x022DE6]=1,[0x022DE8]=1}
local function s16(v) v = v & 0xffff; if v >= 0x8000 then return v - 0x10000 end return v end
local function s32(v) if v >= 0x80000000 then return v - 0x100000000 end return v end
local function on_ctl(o, d)
  if injecting then return end
  if o == 0x818006 or o == 0x818016 then bank = (o == 0x818016) and 1 or 0; rec = {}
  elseif o == 0x81801A and rec and MPC.value ~= 0x02E464 and MPC.value ~= 0x02E414 then
    jobs[#jobs+1] = rec; rec = nil
  end
end
local function on_data(o, d) if injecting or not rec then return end; rec[#rec+1] = {o, d & 0xffff, MPC.value} end
local function lerp_job(A, B, t)
  local bv = {}; for _,w in ipairs(B) do bv[w[1]] = w[2] end
  local out, i = {}, 1
  while i <= #A do
    local o, d, pc = A[i][1], A[i][2], A[i][3]
    local nx = A[i+1]
    if POS[pc] and nx and nx[1] == o + 2 and bv[o] and bv[o+2] then
      local va, vb = s32((d << 16) | nx[2]), s32((bv[o] << 16) | bv[o+2])
      local v = math.floor(va + (vb - va) * t + 0.5) & 0xffffffff
      out[#out+1] = {o, v >> 16}; out[#out+1] = {o+2, v & 0xffff}; i = i + 2
    else
      if MAT[pc] and bv[o] then d = math.floor(s16(d) + (s16(bv[o]) - s16(d)) * t + 0.5) & 0xffff end
      out[#out+1] = {o, d}; i = i + 1
    end
  end
  return out
end
local function snapshot() local s = {}; for a = 0, 0x1FFE do s[a] = ad:read_u16(a) end; return s end
local function restore(s) for a = 0, 0x1FFE do ad:write_u16(a, s[a]) end end
local function start_inject(t)
  local job = lerp_job(jobs[#jobs-1], jobs[#jobs], t)
  restore(snap)
  ms:write_u16(0x81800A, 0); ms:write_u16(0x818008, 0)
  ms:write_u16(bank == 1 and 0x818006 or 0x818016, 0)       -- ADSP writes the already-copied bank
  for _,w in ipairs(job) do ms:write_u16(w[1], w[2]) end
  ms:write_u16(0x818018, 0); ms:write_u16(0x81801A, 0)
  state = "running"
end
local releasing = false
local function on_done(o, d)
  if (d & 0xffff) ~= 1 or releasing then return end
  if not injecting and state == "idle" and frame >= TF and #jobs >= 2 and nh < NH then
    state = "pending"; return 0
  end
  if injecting and state == "running" then state = "done"; return 0 end
end
local function read_output(name)
  local n = ms:read_u16(0x810000)
  local f = io.open(name, "w"); f:write("7000\n")
  for i = 1, n do f:write(string.format("%04X\n", ms:read_u16(0x810000 + 2*i))) end; f:close()
  return n
end
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
  if state == "pending" then
    nh = nh + 1; injecting = true; snap = snapshot(); ti = 1; start_inject(TS[ti])
  elseif state == "done" then
    ms:write_u16(bank == 1 and 0x818016 or 0x818006, 0); state = "readable"
  elseif state == "readable" then
    local n = read_output(string.format("%s_p%02d_t%.2f.words", TAG, nh, TS[ti]))
    L(string.format("pair %d (jobs %d->%d) t=%.2f: %d words", nh, #jobs-1, #jobs, TS[ti], n))
    if ti < #TS then ti = ti + 1; start_inject(TS[ti])
    else restore(snap); injecting = false; state = "idle"; releasing = true; ms:write_u16(0xFF9BB4, 1); releasing = false end
  end
  if nh >= NH and state == "idle" then log:close(); manager.machine:exit() end
end)
