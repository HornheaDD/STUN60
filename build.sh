#!/bin/bash
# Build the custom S.T.U.N. Runner 60fps emulator (MAME 0.285 + stun60-mame0285.patch) into build/mame-mame0285/stun60.
# Usage: ./build.sh            Linux build for this PC (links system libraries)
#        ./build.sh package    Linux build for the portable AppImage (glibc >= 2.36 shim, static libstdc++, no PipeWire link)
#        ./build.sh windows    Windows x64 cross-build (needs mingw-w64-gcc with posix threads) -> build/mame-mame0285/stun60.exe
# Needs: base-devel/build-essential, python3, SDL2 + SDL2_ttf, libpulse, alsa, libx11, libxi, fontconfig, OpenGL headers, curl, patch.
set -e
cd "$(dirname "$0")"
ROOT="$PWD"; SRC="$ROOT/build/mame-mame0285"; MODE="${1:-native}"
mkdir -p build
if [ ! -d "$SRC" ]; then
  [ -f build/mame0285.tar.gz ] || curl -L -o build/mame0285.tar.gz https://github.com/mamedev/mame/archive/refs/tags/mame0285.tar.gz
  tar -xzf build/mame0285.tar.gz -C build
fi
cd "$SRC"
if patch -p1 -R --dry-run -s < "$ROOT/stun60-mame0285.patch" >/dev/null 2>&1; then echo "patch already applied"
else patch -p1 -b < "$ROOT/stun60-mame0285.patch"; fi
COMMON=(SUBTARGET=stun60 SOURCES=src/mame/atari/harddriv.cpp NOWERROR=1 USE_QTDEBUG=0 TOOLS=0 TESTS=0 OPTIMIZE=2 -j"$(nproc)")
case "$MODE" in
  native)
    make "${COMMON[@]}" ;;
  package)
    gcc -O2 -fPIC -fno-builtin -c "$ROOT/package/linux/glibc_compat.c" -o "$ROOT/package/linux/glibc_compat.o"
    # make doesn't recompile when only defines change: drop the objects that depend on NO_USE_PIPEWIRE
    find build/linux_gcc/obj -name 'pipewire_sound.*' -o -name 'osdobj_common.o' 2>/dev/null | xargs -r rm -f
    make REGENIE=1 NO_USE_PIPEWIRE=1 \
      LDOPTS="-static-libstdc++ -static-libgcc $(cat "$ROOT/package/linux/wrapflags.txt") $ROOT/package/linux/glibc_compat.o" \
      "${COMMON[@]}" ;;
  windows)
    M="$ROOT/build/mingw64/bin"; mkdir -p "$M"
    for t in gcc g++ gcc-ar gcc-nm gcc-ranlib; do
      s=/usr/bin/x86_64-w64-mingw32-$t-posix; [ -e "$s" ] || s=/usr/bin/x86_64-w64-mingw32-$t; ln -sf "$s" "$M/x86_64-w64-mingw32-$t"
    done
    for t in windres ar ranlib nm strip objdump ld; do ln -sf /usr/bin/x86_64-w64-mingw32-$t "$M/x86_64-w64-mingw32-$t"; done
    ln -sf /usr/bin/x86_64-w64-mingw32-windres "$M/windres"
    PATH="$M:$PATH" make TARGETOS=windows CROSS_BUILD=1 MINGW64="$ROOT/build/mingw64" PTR64=1 "${COMMON[@]}" ;;
  *) echo "unknown mode: $MODE (native | package | windows)"; exit 1 ;;
esac
echo "Done: $SRC/stun60$([ "$MODE" = windows ] && echo .exe)"
