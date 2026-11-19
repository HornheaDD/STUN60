import sys
from dec import polys
def info(p):
    lines=p[2]; ys=[l[0] for l in lines]
    area=sum(b-a+1 for _,a,b in lines)
    cx=sum((a+b)/2*(b-a+1) for _,a,b in lines)/max(area,1); cy=sum(y*(b-a+1) for y,a,b in lines)/max(area,1)
    return dict(col=p[1]&0x3ff, flags=p[1], cx=cx, cy=cy, area=area, nv=len(p[5]))
for pre in sys.argv[1:]:
    seqs=[]
    for i in range(1,17):
        P=[info(p) for p in polys(f'{pre}_{i}') if p[0]=='poly']; seqs.append(P)
    print(pre, 'counts', [len(s) for s in seqs])
    for i in range(len(seqs)-1):
        A,B=seqs[i],seqs[i+1]
        ca=[p['col'] for p in A]; cb=[p['col'] for p in B]
        same=sum(1 for x,y in zip(ca,cb) if x==y)
        # lcs on colour sequence
        n,m=len(ca),len(cb); L=[[0]*(m+1) for _ in range(n+1)]
        for x in range(n-1,-1,-1):
            for y in range(m-1,-1,-1):
                L[x][y]=L[x+1][y+1]+1 if ca[x]==cb[y] else max(L[x+1][y],L[x][y+1])
        print(f' {i+1}->{i+2}: n={n},{m} same-pos-colour={same} lcs={L[0][0]}')
