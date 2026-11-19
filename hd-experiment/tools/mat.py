# search for 3x3 rotation matrices (orthonormal rows) of signed 16-bit fixed-point words
import sys, struct, math
def words(b): return struct.unpack('>%dh'%(len(b)//2), b)
for fn in sys.argv[1:]:
    w=words(open(fn,'rb').read()); hits=[]
    for scale in (0x4000,0x7FFF,0x8000,0x2000,0x1000):
      for stride in (1,2):  # stride 2 = 32-bit entries, take high or low word
        for i in range(len(w)-9*stride):
            m=[w[i+k*stride]/scale for k in range(9)]
            r=[m[0:3],m[3:6],m[6:9]]
            ok=True
            for a in range(3):
                n=sum(x*x for x in r[a])
                if abs(n-1)>0.02: ok=False;break
            if not ok: continue
            if any(abs(sum(r[a][k]*r[b][k] for k in range(3)))>0.02 for a,b in ((0,1),(0,2),(1,2))): continue
            if sum(1 for x in m if abs(x)>0.01)<4: continue   # skip identity-like
            hits.append((i*2,hex(scale),stride,[round(x,3) for x in m]))
    print(fn,len(hits))
    for h in hits[:20]: print('  off %05X scale %s stride %d %s'%h)
