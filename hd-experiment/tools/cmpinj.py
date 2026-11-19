import glob, sys
from PIL import Image, ImageDraw
from words import mk
from interp import prep, YO
def raster(tag):
    im=Image.new('I',(512,208),-1); d=ImageDraw.Draw(im)
    for p in prep(tag): d.polygon([(x,y-YO) for x,y in p['o']], fill=p['col'])
    return list(im.get_flattened_data())
def sc(a,b): return sum(1 for x,y in zip(a,b) if x==y)/len(a)
pre=sys.argv[1]
lists=sorted(glob.glob(pre+'_list*.words')); inj=sorted(glob.glob(pre+'_t*.words'))
R={f:raster(mk(f)) for f in lists+inj}
for f in inj:
    best=sorted(((sc(R[f],R[g]),g) for g in lists), reverse=True)[:3]
    print(f, ' '.join(f'{g[len(pre)+1:-6]}={s:.3f}' for s,g in best))
a,b=R[inj[0]],R[inj[-1]]; m=R[inj[1]]
print('t0 vs t1 %.3f | t0.5 vs t0 %.3f | t0.5 vs t1 %.3f'%(sc(a,b),sc(m,a),sc(m,b)))
