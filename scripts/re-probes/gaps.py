import wave, array, sys, math
def load(fn):
    w=wave.open(fn); r=w.getframerate(); ch=w.getnchannels()
    a=array.array('h', w.readframes(w.getnframes())); return a[::ch], r
for fn, g0 in ((sys.argv[1], int(sys.argv[3])), (sys.argv[2], int(sys.argv[4]))):
    a, r = load(fn); i0=int(g0/60*r); W=r//200  # 5 ms windows
    e=[]
    for k in range(i0, min(len(a), i0+r*20)-W, W):
        x=a[k:k+W]; e.append(math.sqrt(sum(v*v for v in x)/W))
    # dropout = window < 10% of the mean of its neighbours 20ms either side
    n=0; ex=[]
    for k in range(4,len(e)-4):
        nb=(sum(e[k-4:k-1])+sum(e[k+2:k+5]))/6
        if nb>800 and e[k]<0.1*nb: n+=1; ex.append(round(k*0.005,3))
    print(fn, "dropouts in 20 s:", n, ex[:12])
