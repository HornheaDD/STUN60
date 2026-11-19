import sys, random
from PIL import Image, ImageDraw
from interp import prep, inbetween, YO
def col(c): random.seed(c*7919); return (random.randrange(40,256),random.randrange(40,256),random.randrange(40,256))
def draw(items):
    im=Image.new('RGB',(512,208)); d=ImageDraw.Draw(im)
    for c,f,pts in items: d.polygon([(x,y-YO) for x,y in pts], fill=col(c), outline=(0,0,0))
    return im
pre=sys.argv[1]; i=int(sys.argv[2])
A,M,B=[prep(f'{pre}_{k}') for k in (i,i+1,i+2)]
ims=[draw([(p['col'],p['f'],p['o']) for p in A]), draw(inbetween(A,B,0.5)), draw([(p['col'],p['f'],p['o']) for p in M]), draw([(p['col'],p['f'],p['o']) for p in B])]
W=Image.new('RGB',(1024,416),'white')
for k,im in enumerate(ims): W.paste(im,((k%2)*512,(k//2)*208))
W.save(sys.argv[3])
