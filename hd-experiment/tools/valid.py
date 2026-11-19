import sys
from PIL import Image, ImageDraw
from interp import prep, inbetween, YO
def raster(items):
    im=Image.new('I',(512,208),-1); d=ImageDraw.Draw(im)
    for col,f,pts in items: d.polygon([(x,y-YO) for x,y in pts], fill=col)
    return list(im.get_flattened_data())
def score(a,b): return sum(1 for x,y in zip(a,b) if x==y)/len(a)
for pre in sys.argv[1:]:
    S=[prep(f'{pre}_{i}') for i in range(1,17)]
    for i in range(0,14):
        A,M,B=S[i],S[i+1],S[i+2]
        truth=raster([(p['col'],p['f'],p['o']) for p in M])
        hold=raster([(p['col'],p['f'],p['o']) for p in A])
        mid=raster(inbetween(A,B,0.5))
        print(f'{pre} {i+1}-{i+3}: hold-previous={score(hold,truth):.3f}  interpolated={score(mid,truth):.3f}')
