import os
import json, sys
def load(t):
    d={}
    for l in open(f't{t}.txt'):
        k,*v=l.split(); d[k]=[int(x,16) for x in v]
    return d
cm={int(k):tuple(v) for k,v in json.load(open(os.path.expanduser('~/mame/hd-experiment/tools/cmap.json'))).items()}
D={t:load(t) for t in (2400,2412,2424,2436,3000,3600)}
T=D[2400]['TAB']
ident=sum(1 for i,w in enumerate(T) if w==((i&0xff)*0x101))
same=sum(1 for w in T if (w>>8)==(w&0xff))
print('table: identity-like',ident,'solid pairs',same,'of 1024; distinct words',len(set(T)))
print('table changes between frames:', {t:sum(a!=b for a,b in zip(T,D[t]['TAB'])) for t in D})
print('palette changes vs 2400:', {t:sum(a!=b for a,b in zip(D[2400]['LO']+D[2400]['HI'],D[t]['LO']+D[t]['HI'])) for t in D})
print('nonsolid examples:',[(i,hex(w)) for i,w in enumerate(T) if (w>>8)!=(w&0xff)][:12])
def rgb(d,pen): return ((d['LO'][pen]>>8)&0xff, d['LO'][pen]&0xff, d['HI'][pen]&0xff)
for bank in range(4):
    err=[];
    for c,ref in cm.items():
        w=T[c]; a,b=w&0xff,w>>8
        ra,rb=rgb(D[2400],bank*256+a),rgb(D[2400],bank*256+b)
        got=tuple((x+y)/2 for x,y in zip(ra,rb))
        err.append(max(abs(x-y) for x,y in zip(got,ref)))
    err.sort(); print(f'bank {bank}: max channel err median {err[len(err)//2]:.0f}, exact(<=2) {sum(e<=2 for e in err)}/{len(err)}, worst {err[-1]:.0f}')
