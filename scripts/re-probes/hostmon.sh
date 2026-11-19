#!/bin/sh
# Logs CPU MHz (avg/min over cores), package temp and the stun60 process CPU% once a second
# while the custom MAME runs. Usage: hostmon.sh out.log [max_seconds]
out=$1; max=${2:-1500}; seen=0; i=0
# temp source: AMD k10temp (Tctl) or Intel coretemp (package), else thermal_zone8 (old Ubuntu laptop)
tf=/sys/class/thermal/thermal_zone8/temp
for h in /sys/class/hwmon/hwmon*; do case $(cat $h/name) in k10temp|coretemp) tf=$h/temp1_input; break;; esac; done
echo "time avgMHz minMHz pkgC mameCPU%" > "$out"
while [ $i -lt $max ]; do
  pid=$(pgrep -x stun60 | head -1)
  if [ -n "$pid" ]; then seen=1; elif [ $seen = 1 ]; then break; fi
  f=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq | awk '{s+=$1; if(m==""||$1<m)m=$1} END{printf "%d %d", s/NR/1000, m/1000}')
  t=$(( $(cat $tf) / 1000 ))
  c=$( [ -n "$pid" ] && ps -o %cpu= -p $pid | tr -d ' ' || echo -)
  echo "$(date +%T) $f $t $c" >> "$out"
  sleep 1; i=$((i+1))
done
