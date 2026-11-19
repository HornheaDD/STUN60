import glob, json, os
from PIL import Image, ImageDraw, ImageFont
from words import mk
from interp import prep, YO
cm={int(k):tuple(v) for k,v in json.load(open('cmap.json')).items()}
def colour(c):
    if c in cm: return cm[c]
    k=min(cm, key=lambda x: abs(x-c)); return cm[k]
PW,PH=720,468; SS=2
sx,sy=PW/512*SS, (PH/208)*SS
cache={}
def panel(tag):
    if tag in cache: return cache[tag]
    im=Image.new('RGB',(PW*SS,PH*SS)); d=ImageDraw.Draw(im,'RGBA')
    for p in prep(tag):
        pts=[(x*sx,(y-YO)*sy) for x,y in p['o']]
        if (p['f']>>10)&3==2: d.polygon(pts, fill=(0,0,0,110))
        else: d.polygon(pts, fill=colour(p['col']))
    im=im.resize((PW,PH),Image.LANCZOS); cache[tag]=im; return im
font=ImageFont.load_default(size=22) if hasattr(ImageFont,'load_default') else None
pairs=sorted(set(f.split('_t')[0] for f in glob.glob('i2_p*_t*.words')))
os.makedirs('frames',exist_ok=True)
n=0
for pr in pairs:
    tags=[mk(f'{pr}_t{t}.words') for t in ('0.00','0.33','0.67')]
    for k in range(3):
        W=Image.new('RGB',(PW*2+12,PH+40),(20,20,20)); d=ImageDraw.Draw(W)
        W.paste(panel(tags[0]),(0,40)); W.paste(panel(tags[k]),(PW+12,40))
        d.text((10,8),"Original: 20 fps",fill='white',font=font); d.text((PW+22,8),"Interpolated by the game's own 3D engine: 60 fps",fill='white',font=font)
        W.save(f'frames/f{n:04d}.png'); n+=1
print(n,'frames')
