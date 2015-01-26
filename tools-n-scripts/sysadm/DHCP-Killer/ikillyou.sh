#!/bin/sh
#
# Oh mann

for i in {498..501}; do 
    MCPART=`printf "%.*d:%.*d\n" "2" "$((${i}%73))" "2" "$((${i}%17))"`
    echo "ip link add link eth0 address 00:00:00:00:${MCPART} eth0.${i} type macvlan"
    echo "ifconfig eth0.${i} up"
    #`dhclient eth0.${i} &`
done
