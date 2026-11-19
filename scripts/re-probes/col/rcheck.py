import os
# draw the captured 3D list with decoded colours (table FFF71D20 -> pen -> palette RAM) and compare with the snapshot
import sys
sys.path.insert(0,os.path.expanduser('~/mame/hd-experiment/tools'))
from collections import Counter
from PIL import Image
from dec import polys, load
YO=0x28
for tf in sys.argv[1:]:
    tag='c'+tf; w,_=load(tag)
    pal=[tuple(int(x,16) for x in l.split()) for l in open(tag+'.pal')]
    rgb=[((lo>>8)&255, lo&255, hi&255) for lo,hi in pal]
    T=[w(0xFFF71D20+16*i) for i in range(1024)]
    for k in range(3):
        snap=Image.open(f'snap{tf}/stunrun/{k:04d}.png').convert('RGB'); sp=snap.load()
        img={}; mode={}
        P=[p for p in polys(tag) if p[0]=='poly']
        for p in P:
            f=p[1]; m=(f>>10)&3; col=rgb[T[f&0x3ff]&0xff]
            for (y,a,b) in p[2]:
                r=y-YO
                if not 0<=r<208: continue
                for x in range(max(a,0),min(b,511)+1):
                    if m==2 and (x+r)&1: continue        # guess: dithered shadow = every other pixel
                    img[(x,r)]=col; mode[(x,r)]=m
        ok=Counter(); tot=Counter()
        for (x,r),c in img.items():
            tot[mode[(x,r)]]+=1
            if max(abs(a-b) for a,b in zip(sp[x,r],c))<=2: ok[mode[(x,r)]]+=1
        cov=len(img)/(512*208)
        print(f'{tag} snap{k}: {len(P)} polys, covers {cov:.0%} of playfield; match by mode:',
              {m:f'{ok[m]}/{tot[m]} ({ok[m]/tot[m]:.1%})' for m in sorted(tot)})
