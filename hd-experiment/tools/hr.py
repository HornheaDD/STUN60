import sys
from collections import Counter
from PIL import Image, ImageDraw
from dec import polys
def nn(im,size):
    W,H=size; w,h=im.size; src=list(im.get_flattened_data())
    xs=[x*w//W for x in range(W)]
    out=[]
    for y in range(H):
        row=(y*h//H)*w; out.extend(src[row+x] for x in xs)
    o=Image.new(im.mode,size); o.putdata(out); return o
tag, snapf = sys.argv[1], sys.argv[2]; YO=0x28
snap=Image.open(snapf).convert('RGB'); sp=snap.load()
P=[p for p in polys(tag) if p[0]=='poly']
# colour per polygon: most common snapshot colour among the pixels it wins
idx={}
for i,p in enumerate(P):
    for (y,a,b) in p[2]:
        for x in range(max(a,0),min(b,511)+1): idx[(x,y)]=i
cols={}
for (x,y),i in idx.items():
    r=y-YO
    if 0<=r<208: cols.setdefault(i,Counter())[sp[x,r]]+=1
OW,OH=1440,1080; SS=3
sx,sy=OW/512*SS, OH/240*SS
img=nn(snap,(OW*SS,OH*SS)); dr=ImageDraw.Draw(img,'RGBA')
for i,p in enumerate(P):
    if i not in cols: continue
    c=cols[i].most_common(1)[0][0]
    f,lines,Lv,Rv=p[1],p[2],p[3],p[4]
    y0=lines[0][0]; y1=lines[-1][0]
    L=[(x,y+0.5) for x,y in Lv]; R=[(x,y+0.5) for x,y in Rv]
    L[0]=(L[0][0],y0); R[0]=(R[0][0],y0); L[-1]=(L[-1][0],y1+1); R[-1]=(R[-1][0],y1+1)
    pts=[(x*sx,(y-YO)*sy) for x,y in L+R[::-1]]
    if (f>>10)&3==2: dr.polygon(pts, fill=(0,0,0,110))   # dithered shadow -> translucent
    else: dr.polygon(pts, fill=c)
img=img.resize((OW,OH),Image.LANCZOS)  # background/sprites come from the original frame
hud=nn(snap.crop((0,208,512,240)),(OW,OH*32//240)); img.paste(hud,(0,OH*208//240))
img.save(tag+'-hd.png')
nn(snap,(OW,OH)).save(tag+'-orig.png')
# zoomed crops for side-by-side
box=(200,250,840,730)
a=Image.open(tag+'-orig.png').crop(box); b=img.crop(box)
W=Image.new('RGB',(1300,480),'white'); W.paste(a,(0,0)); W.paste(b,(660,0)); W.save(tag+'-zoom.png')
