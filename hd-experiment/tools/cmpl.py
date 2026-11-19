import sys
from PIL import Image, ImageDraw
from interp import prep, YO
def raster(tag):
    im=Image.new('I',(512,208),-1); d=ImageDraw.Draw(im)
    for p in prep(tag): d.polygon([(x,y-YO) for x,y in p['o']], fill=p['col'])
    return list(im.get_flattened_data())
def sc(a,b): return sum(1 for x,y in zip(a,b) if x==y)/len(a)
R={}
def r(t):
    if t not in R: R[t]=raster(t)
    return R[t]
for k in (2,4,6):
    print(f"modified list {k}: same as its own previous list {k-1}: {sc(r(f'kprev_{k}'),r(f'kprev_{k-1}')):.3f} | same as unmodified run's list {k}: {sc(r(f'kprev_{k}'),r(f'knone_{k}')):.3f}")
    print(f"   baseline: unmodified list {k} vs {k-1}: {sc(r(f'knone_{k}'),r(f'knone_{k-1}')):.3f}; list {k-1} runs identical: {sc(r(f'kprev_{k-1}'),r(f'knone_{k-1}')):.3f}")
