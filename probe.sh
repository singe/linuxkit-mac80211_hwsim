#!/bin/sh
function failed {
  printf "Wifi kernel module install FAILED\n"
  #/sbin/poweroff -f
  exit 1
}

radios=$1
#dir="/lib/modules/4.14.131-linuxkit/kernel/"
dir="/kmod/"
uname -a
modinfo $dir/cfg80211.ko || failed
modinfo $dir/mac80211.ko || failed
modinfo $dir/mac80211_hwsim.ko || failed
insmod $dir/cfg80211.ko || failed
insmod $dir/mac80211.ko || failed
insmod $dir/mac80211_hwsim.ko radios=$radios || failed
[ -n "$(lsmod | grep -o 'mac80211_hwsim')" ] || failed

printf "Wifi kernel module install SUCCESSFUL\n"
