import sys,statistics as st
for fn in sys.argv[1:]:
    ev=[(l.split()[0],float(l.split()[1])) for l in open(fn)]
    frames=[]; cur=None
    for tag,t in ev:
        if tag=="S": cur={"S":t}; frames.append(cur)
        elif cur is None: continue
        elif tag=="L" and "L" not in cur: cur["L"]=t
        elif tag in "DF" and "L" in cur and "D" not in cur and (t%1)>0.06: cur["D"]=t
    print("==",fn)
    for a in range(20,91,10):
        fr=[f for f in frames if a*60<=f["S"]<(a+10)*60 and "L" in f and "D" in f]
        if not fr: continue
        wl=[f["L"]-f["S"] for f in fr]; dr=[f["D"]-f["L"] for f in fr]
        print(f" t={a}-{a+10}s frames={len(fr):3d} fps={len(fr)/10:4.1f}  wait-list mean {st.mean(wl):.2f} max {max(wl):.2f} | draw mean {st.mean(dr):.2f} min {min(dr):.2f} max {max(dr):.2f} (refreshes)")
