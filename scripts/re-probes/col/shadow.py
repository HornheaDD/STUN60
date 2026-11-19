import os
import sys
sys.path.insert(0,os.path.expanduser('~/mame/hd-experiment/tools'))
from collections import Counter, defaultdict
from PIL import Image
from dec import polys, load
YO=0x28
best={'2400':0,'3000':1,'3600':0}
hit=defaultdict(Counter); 
for tf,k in best.items():
    tag='c'+tf; w,_=load(tag)
    rgb=[((lo>>8)&255, lo&255, hi&255) for lo,hi in ([int(x,16) for x in l.split()] for l in open(tag+'.pal'))]
    T=[w(0xFFF71D20+16*i) for i in range(1024)]
    sp=Image.open(f'snap{tf}/stunrun/{k:04d}.png').convert('RGB').load()
    for p in polys(tag):
        if p[0]!='poly' or (p[1]>>10)&3!=2: continue
        f=p[1]; col=rgb[T[f&0x3ff]&0xff]
        print(tag,'shadow poly flags %04X idx %d low8 %d colour %s'%(f,f&0x3ff,f&0xff,col))
        for (y,a,b) in p[2]:
            r=y-YO
            if not 0<=r<208: continue
            for x in range(max(a,0),min(b,511)+1):
                hit[(f&0xff)==4][(x%8, y%8, max(abs(c-d) for c,d in zip(sp[x,r],col))<=2)]+=1
for v,h in hit.items():
    print('variant low8==4' if v else 'variant other')
    for yy in range(8):
        print('  y%8=',yy,' '.join('%3.0f%%'%(100*h[(xx,yy,True)]/max(1,h[(xx,yy,True)]+h[(xx,yy,False)])) for xx in range(8)))
