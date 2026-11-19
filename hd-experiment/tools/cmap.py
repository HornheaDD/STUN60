# colour index -> RGB, sampled from captured frames with matching snapshots
import json
from collections import Counter
from PIL import Image
from dec import polys
YO=0x28
votes={}
for tag in ['c2400','c3000','c3600','c2412','c2424','c2436']:
    snap=Image.open(tag+'-0.png').convert('RGB'); sp=snap.load()
    P=[p for p in polys(tag) if p[0]=='poly']
    idx={}
    for i,p in enumerate(P):
        for (y,a,b) in p[2]:
            for x in range(max(a,0),min(b,511)+1): idx[(x,y)]=i
    for (x,y),i in idx.items():
        r=y-YO
        if 0<=r<208:
            c=P[i][1]&0x3ff
            if (P[i][1]>>10)&3==0: votes.setdefault(c,Counter())[sp[x,r]]+=1
cm={c:list(v.most_common(1)[0][0]) for c,v in votes.items() if v.most_common(1)[0][1]>=4}
json.dump(cm,open('cmap.json','w')); print(len(cm),'colours')
