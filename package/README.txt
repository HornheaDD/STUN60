S.T.U.N. Runner 60fps
=====================

Atari's S.T.U.N. Runner (1989) at 60 frames per second and the correct game speed.
This is a custom build of MAME 0.285 (only the S.T.U.N. Runner driver) plus a Lua script.
The game's own 3D chip renders two extra in-between frames per game tick, with the camera
and objects interpolated, so the motion is real 60 fps (not blended frames).
Optional CRT look (scanlines, shadow mask, glow) via MAME's BGFX shaders.

ROMs are NOT included. You need the MAME 0.285 romset "stunrun.zip" (the parent set).

Linux (AppImage)
  1. Put STUNRunner60-x86_64.AppImage and stunrun.zip in the same folder
     (or put stunrun.zip in ~/.local/share/stun60/roms).
  2. chmod +x STUNRunner60-x86_64.AppImage, then double-click it or run it.
  Needs glibc 2.36 or newer: Debian 12+, Ubuntu 24.04+, Fedora 37+, Arch/CachyOS and other
  current distros. Uses the system's OpenGL/Vulkan, audio (PulseAudio/PipeWire/ALSA) and fonts.
  If FUSE is missing: ./STUNRunner60-x86_64.AppImage --appimage-extract-and-run
  The .tar.gz is the same thing unpacked: extract it, put stunrun.zip in the folder, run ./run
  Saved data, log and settings: ~/.local/share/stun60

Windows (64-bit, Windows 10 or 11)
  1. Extract the zip anywhere.
  2. Put stunrun.zip next to STUNRunner60.exe (or in the roms folder).
  3. Run STUNRunner60.exe.
  Saved data, log and settings: the data folder next to the exe.

Controls and tips
  - MAME's normal controls (5 = coin, 1 = start, Tab = MAME menu, Esc = quit).
  - O cycles the on-screen overlay: small (fps) / full (stats) / off. The choice is remembered.
  - C cycles the screen effect: CRT scanlines (deluxe) / CRT scanlines (sharp) / off.
    The choice is remembered. The first launch starts with CRT deluxe.
    (Same setting as Tab > Slider Controls > "Window 0, Screen 0 Effect", which lists more effects.)
  - The CPUs are overclocked (68010 x3, video x4, 3D x8), which this needs; the launcher sets it.
    Advanced: the environment variable STUN60_CLOCK (e.g. maincpu=3,gsp=4,adsp=8) overrides it,
    and STUN60_CRT=deluxe|geom|off forces a screen effect for one launch.
  - Level-change and attract-mode text screens stay at 20 fps (nothing 3D to interpolate there).
  - It needs a reasonably fast CPU: roughly an Intel 8th-gen quad-core laptop chip or better.
  - stun60.log in the data folder shows per-second stats (drawn fps, game ticks, timing).
