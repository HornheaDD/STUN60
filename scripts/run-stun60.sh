#!/bin/sh
# Start the custom S.T.U.N. Runner 60fps build with explicit paths (no dependency on a distro MAME package / /etc/mame).
# Extra arguments are passed to MAME (e.g. -window).
# Video is BGFX with our own shader + artwork folders. Screen effect: press C in-game (CRT deluxe / CRT sharp / off), or
#   Tab > Slider Controls > "Window 0, Screen 0 Effect" (crt-geom-deluxe, crt-geom, default = plain, ...).
#   MAME saves the choice in ~/.mame/cfg/stunrun.cfg and restores it next launch. First launch defaults to crt-geom-deluxe.
# STUN60_CRT=deluxe|geom|off forces an effect for this launch (overrides the saved choice).
# STUN60_SYNC=1: pace the game to the monitor refresh (-syncrefresh -waitvsync) instead of the game's ~60.2 Hz.
export STUN60_CLOCK="${STUN60_CLOCK:-maincpu=3,gsp=4,adsp=8}"
M="$HOME/.mame"
B="$HOME/mame/build/mame-mame0285"
mkdir -p "$M/cfg" "$M/nvram" "$M/snap"
case "${STUN60_CRT:-}" in
  deluxe) set -- -bgfx_screen_chains crt-geom-deluxe "$@" ;;
  geom)   set -- -bgfx_screen_chains crt-geom "$@" ;;
  off)    set -- -bgfx_screen_chains default "$@" ;;
  *)      grep -q 'chain=' "$M/cfg/stunrun.cfg" 2>/dev/null || set -- -bgfx_screen_chains crt-geom-deluxe "$@" ;;
esac
[ "${STUN60_SYNC:-0}" = 1 ] && set -- -syncrefresh -waitvsync "$@"
exec "$B/stun60" stunrun -inipath "$M" -rompath "$HOME/mame/roms" -artpath "$M/artwork;$B/artwork" \
  -cfg_directory "$M/cfg" -nvram_directory "$M/nvram" -snapshot_directory "$M/snap" \
  -video bgfx -bgfx_path "$B/bgfx" \
  -sound portaudio -audio_latency 3 -autoboot_script "$HOME/mame/scripts/stunrun-interp60.lua" "$@" \
  2> "$HOME/mame/stun60-stderr.log"
