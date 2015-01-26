#!/bin/bash
#
# Oh mann

for i in {1..5}; do 
    MCPART=`printf "%.*d:%.*d:%.*d\n" "2" "$((${i}%100))" "2" "$((${i}%99))" "2" "$((${i}%98))"` 
  #  ip link add link eth0 address 00:0b:00:${MCPART} eth0.${i} type macvlan
  #  ifconfig eth0.${i} up
  # (dhclient eth0.${i} 2> /dev/null &)
    ip link delete eth0.${i} type macvlan
done
