#!/bin/sh

for i in stop init start; do
  wget --proxy=off -O /dev/null \
"http://manager:manager@localhost:8181/invoke?objectname=OpenNMS%3AName%3DPollerd&operation=$i"; 
done
