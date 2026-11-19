import wave, array, sys, math
def load(fn):
    w=wave.open(fn); r=w.getframerate(); ch=w.getnchannels()
    a=array.array('h', w.readframes(w.getnframes()))
    return a[::ch], r
s,r=load(sys.argv[1]); t,_=load(sys.argv[2])
fp=1/60.2  # approx frame period
def win(a, f0, sec):
    i=int(f0/60.0*r); return a[i:i+int(sec*r)]
def rms(x): return math.sqrt(sum(v*v for v in x)/max(1,len(x)))
g0s, g0t = int(sys.argv[3]), int(sys.argv[4])
print("sec  stock  script")
for k in range(0, int(sys.argv[5]) if len(sys.argv)>5 else 30):
    a=win(s, g0s+k*60, 1); b=win(t, g0t+k*60, 1)
    print(f"{k:3d} {rms(a):7.0f} {rms(b):7.0f}")
