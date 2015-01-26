#!/bin/sh
#
# Oh Frau

for i in {1..9999}; do 
    # echo "ifconfig eth0.${i} down"
    ip link delete eth0.${i} type macvlan
done
