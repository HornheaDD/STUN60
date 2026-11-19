import os
import sys
sys.path.insert(0,os.path.expanduser('~/mame/hd-experiment/tools'))
from collections import Counter
from PIL import Image
from dec import polys, load
YO=0x28
for tf,k in {'2400':0,'3000':1,'3600':0}.items():
    tag='c'+tf; w,_=load(tag)
    sp=Image.open(f'snap{tf}/stunrun/{k:04d}.png').convert('RGB').load()
    for p in polys(tag):
        if p[0]!='poly' or (p[1]>>10)&3!=2: continue
        y0=p[2][0][0]; xl0=p[2][0][1]
        h=Counter(); n=Counter()
        for (y,a,b) in p[2]:
            r=y-YO
            if not 0<=r<208: continue
            for x in range(max(a,0),min(b,511)+1):
                key=(x%4,y%2); n[key]+=1
                if sp[x,r]==(0,0,0): h[key]+=1
        fr={kk:h[kk]/n[kk] for kk in n}
        on=sorted(kk for kk,v in fr.items() if v>0.6)
        print(tag,'y0 %3d xl0 %3d rows %2d  black-at (x%%4,y%%2): %s  others max %.2f'%(y0,xl0,len(p[2]),on,max([v for kk,v in fr.items() if kk not in on]+[0])))
