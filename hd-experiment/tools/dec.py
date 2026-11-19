import sys
from collections import Counter
def load(tag):
    d=open(tag+'.bin','rb').read()
    a7=int(open(tag+'.txt').read().split()[0],16)
    def w(a): o=(a-0xFFF00000)//8; return d[o]|d[o+1]<<8
    return w,a7
def s16(v): return v-0x10000 if v&0x8000 else v
def polys(tag):
    w,a7=load(tag)
    base=a7+16
    cnt=w(base); a3=base+cnt*16
    out=[]
    while True:
        off=w(a3); a3+=16
        if off&0x8000: break
        a=base+off*16
        f=w(a); a+=16
        if f&0x8000: out.append(('end',f)); continue
        if f&0x1000: out.append(('alt',f,a)); continue
        xl=w(a); xr=w(a+16); y=w(a+32); a+=48
        # fixed point accumulators: value = int + frac/2^32 ; frac starts 0.5
        L=xl+0.5; R=xr+1+0.5   # continuous positions incl. rounding bias
        lines=[(y,xl,xr)]
        Lv=[(xl,y)]; Rv=[(xr+1,y)]
        cy=y; Lc=xl+0.0; Rc=xr+1.0
        lx=xl*65536*65536+0x80000000; rx=xr*65536*65536+0x80000000
        segs=[]
        while True:
            sr=w(a)|w(a+16)<<16
            if sr==0xFFFFFFFF: break
            sl=w(a+32)|w(a+48)<<16; n=w(a+64); a+=80
            sr_=s16(sr>>16)+(sr&0xffff)/65536; sl_=s16(sl>>16)+(sl&0xffff)/65536
            segs.append((sl_,sr_,n))
            for k in range(n-1):
                lx+= (s16(sl>>16)<<32) + ((sl&0xffff)<<16)
                rx+= (s16(sr>>16)<<32) + ((sr&0xffff)<<16)
                cy+=1
                lines.append((cy, lx>>32, rx>>32))
            Lc+=sl_*(n-1); Rc+=sr_*(n-1)
            Lv.append((Lc,cy)); Rv.append((Rc+1,cy))
        out.append(('poly',f,lines,Lv,Rv,segs))
    return out
if __name__=='__main__':
    P=polys(sys.argv[1])
    c=Counter(p[0] for p in P); print(c)
    print(Counter((p[1]>>10)&3 for p in P if p[0]=='poly'))
    for p in P[:3]: print(p[1:2], p[2][:3] if p[0]=='poly' else '', p[5] if p[0]=='poly' else '')
