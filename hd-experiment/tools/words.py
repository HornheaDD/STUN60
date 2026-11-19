import os
def mk(wordsfile):
    """turn a '7000 + block' word list into a fake GSP RAM image usable by dec.polys"""
    tag=wordsfile[:-6]
    ws=[int(x,16) for x in open(wordsfile).read().split()]
    img=bytearray(0x20000); A=0xFFF80000
    for i,w in enumerate(ws):
        o=(A+16*i-0xFFF00000)//8; img[o]=w&0xff; img[o+1]=w>>8
    open(tag+'.bin','wb').write(img); open(tag+'.txt','w').write('%X\n'%A)
    return tag
