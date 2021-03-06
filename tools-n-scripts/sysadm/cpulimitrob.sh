#! /bin/bash
# Description:
# 
# If you want to decrease the CPU demands for an application
# you can use this very simple and ugly "hack". 
# I use it when I convert videos on my MacBook Pro
# to prevent it from getting to warm. Even if the CPU is IDLE this hack
# will prevent the application to use the CPU during Sleep Time
# (in contrast to renice/nice commands which will take all IDLE time). 
# This means the conversions will take longer time, but I 
# don't care because I run it at night.
#
# There is similar c program for Linux called cpulimit, but it wont
# compile on my Mac.
#
# Usage:  sudo ./cpulimitrob.sh
#
# Hint: To get the PID, run first top -u command in one Terminal window. 
#
#
echo "Which process ID (PID)? "
read pid

echo "Sleep time in seconds? "
read sleeptime

echo "Run time in seconds (e.g 0.5 or 1 …)? "
read runtime

i=1
dot=.

while true; do
    if [ $i -eq 1 ]; then
	kill -SIGSTOP $pid
	sleep $sleeptime
	i=0
    else
	kill -SIGCONT $pid
        sleep $runtime
        i=1
    fi
    echo -n $dot
done

