import os
"""S.T.U.N. Runner polygon colour decode (verified 2026-11-17).
poly flags: low10 = colour index, bits10-11 = mode (2 = shadow).
pen = word at GSP FFF71D20 + 16*index, low byte (table is constant; both bytes equal, no dither pairs).
RGB = palette RAM (bank 0) entry pen: R = lo>>8, G = lo&255, B = hi&255 (shares :mainpcb:gsp_palram_lo/hi).
The palette changes over time, so read it per frame.
Mode 2 (shadow): pen 20 (black) on 1 pixel of 4: x%4==0 on even list-y rows, x%4==2 on odd rows (screen space)."""
import sys
sys.path.insert(0,os.path.expanduser('~/mame/hd-experiment/tools'))
from dec import polys, load
YO=0x28
def palette(tag):
    return [((lo>>8)&255, lo&255, hi&255) for lo,hi in ([int(x,16) for x in l.split()] for l in open(tag+'.pal'))]
def table(w): return [w(0xFFF71D20+16*i) & 0xff for i in range(1024)]
def shadow_on(x,y): return x%4 == (0 if y%2==0 else 2)
def render(tag):
    w,_=load(tag); rgb=palette(tag); T=table(w); img={}
    for p in polys(tag):
        if p[0]!='poly': continue
        f=p[1]; m=(f>>10)&3; col=rgb[T[f&0x3ff]]
        for (y,a,b) in p[2]:
            r=y-YO
            if not 0<=r<208: continue
            for x in range(max(a,0),min(b,511)+1):
                if m==2 and not shadow_on(x,y): continue
                img[(x,r)]=col
    return img
if __name__=='__main__':
    from PIL import Image
    for tf,k in {'2400':0,'3000':1,'3600':0}.items():
        img=render('c'+tf); sp=Image.open(f'snap{tf}/stunrun/{k:04d}.png').convert('RGB').load()
        ok=sum(1 for (x,r),c in img.items() if sp[x,r]==c)
        print(f'frame {tf}: {ok}/{len(img)} drawn pixels exact ({ok/len(img):.3%})')
