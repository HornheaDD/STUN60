import math
from dec import polys
import os
YO=0x28
CP=float(os.getenv('CP','1e9'))
def outline(p):
    f,lines,Lv,Rv=p[1],p[2],p[3],p[4]
    y0=lines[0][0]; y1=lines[-1][0]
    L=[(x,y+0.5) for x,y in Lv]; R=[(x,y+0.5) for x,y in Rv]
    L[0]=(L[0][0],y0); R[0]=(R[0][0],y0); L[-1]=(L[-1][0],y1+1); R[-1]=(R[-1][0],y1+1)
    return L+R[::-1]
def resample(pts,K=48):
    n=len(pts); seg=[]; tot=0
    for i in range(n):
        a,b=pts[i],pts[(i+1)%n]; d=math.dist(a,b); seg.append(d); tot+=d
    if tot==0: return [pts[0]]*K
    out=[]; i=0; acc=0
    for k in range(K):
        t=tot*k/K
        while acc+seg[i]<t and i<n-1: acc+=seg[i]; i+=1
        a,b=pts[i],pts[(i+1)%n]; u=(t-acc)/seg[i] if seg[i] else 0
        out.append((a[0]+(b[0]-a[0])*u,a[1]+(b[1]-a[1])*u))
    return out
def prep(tag):
    out=[]
    for p in polys(tag):
        if p[0]!='poly': continue
        o=outline(p); A=0; cx=cy=0
        for i in range(len(o)):
            (x1,y1),(x2,y2)=o[i],o[(i+1)%len(o)]; c=x1*y2-x2*y1; A+=c; cx+=(x1+x2)*c; cy+=(y1+y2)*c
        if abs(A)<1e-9: cx=sum(x for x,_ in o)/len(o); cy=sum(y for _,y in o)/len(o)
        else: cx/=3*A; cy/=3*A
        out.append(dict(f=p[1],col=p[1]&0x3ff,o=o,c=(cx,cy),r=resample(o)))
    return out
def align(A,B,maxd=60,gap=30):
    n,m=len(A),len(B); INF=1e18
    D=[[INF]*(m+1) for _ in range(n+1)]; D[n][m]=0
    for i in range(n,-1,-1):
        for j in range(m,-1,-1):
            if i==n and j==m: continue
            best=INF
            if i<n: best=min(best,D[i+1][j]+gap)
            if j<m: best=min(best,D[i][j+1]+gap)
            if i<n and j<m:
                d=math.dist(A[i]['c'],B[j]['c'])+(0 if A[i]['col']==B[j]['col'] else CP)
                if d<maxd: best=min(best,D[i+1][j+1]+d*0.5)
            D[i][j]=best
    i=j=0; pairs=[]
    while i<n or j<m:
        if i<n and j<m:
            d=math.dist(A[i]['c'],B[j]['c'])+(0 if A[i]['col']==B[j]['col'] else CP)
            if d<maxd and abs(D[i][j]-(D[i+1][j+1]+d*0.5))<1e-6: pairs.append((i,j)); i+=1; j+=1; continue
        if i<n and abs(D[i][j]-(D[i+1][j]+gap))<1e-6: pairs.append((i,None)); i+=1; continue
        pairs.append((None,j)); j+=1
    return pairs
def best_rot(ra,rb):
    K=len(ra); best=None
    for s in range(K):
        e=sum((ra[k][0]-rb[(k+s)%K][0])**2+(ra[k][1]-rb[(k+s)%K][1])**2 for k in range(0,K,4))
        if best is None or e<best[0]: best=(e,s)
    s=best[1]; return [rb[(k+s)%K] for k in range(K)]
def inbetween(A,B,t):
    """list of (col, flags, pts) in draw order"""
    out=[]
    for i,j in align(A,B):
        if i is not None and j is not None:
            ra=A[i]['r']; rb=best_rot(ra,B[j]['r'])
            pts=[(a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t) for a,b in zip(ra,rb)]
            out.append((A[i]['col'] if t<0.5 else B[j]['col'],B[j]['f'],pts))
        elif i is not None:
            if t<0.5: out.append((A[i]['col'],A[i]['f'],A[i]['o']))
        else:
            if t>=0.5: out.append((B[j]['col'],B[j]['f'],B[j]['o']))
    return out
