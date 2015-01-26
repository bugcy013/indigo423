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
# Usage:  sudo ./cpulimit.sh
#
 
#################################
# config
sleeptime_default=0.5   # in seconds
runtimep_default=50     # in percent (50 = same as sleeptime) 
reporttime=30           # report every x seconds while running
# PROCESSLISTformat: pid has to be on the second position
PROCESSLISTformat="ppid,pid,user,%cpu,%mem,start,cputime,stime,command" 
#PROCESSLISTformat="ppid,pid,user,%cpu,%mem,start,cputime,stime,rss,vsz,cpu,re,wq,wqr,stat,nsigs,command" 
 
 
#################################
# dont change anything below here
 
pid=""
scriptuser=$(id -u)
 
# run if user hits control-c
control_c()
{
  echo ""
  if [ "$pid" != "" ]; then
    echo -en "\n*** Ouch! Stop throtteling of PID $pid. Exiting ***\n"
    kill -SIGCONT $pid
  fi
  echo ""
  exit $?
}
 
# trap keyboard interrupt (control-c)
trap control_c SIGINT
 
pidstring()
{
  # takes pid as argument
  ps -p $1 -w -o pid,user,%cpu,%mem,start,cputime,command 2>/dev/null
}
 
isnumber()
{
  if [[ "$1" =~ ^[0-9]*([.][0-9]+)?$ ]] ; then
    return 0
  else
    return 1
  fi
}
 
#################################
# main
cat << EOF
 
  This script will throttle a chosen process as you like it.
  Therefore your cpu runs cooler - hopefully.
EOF
if [ "$scriptuser" != "0" ]; then
cat << EOF
 
  You're not root! 
  If you want to controll processes that you dont own,
  please run via sudo.
EOF
fi
 
PIDSTRING=""
until [ "$PIDSTRING" != "" ]; do
  #PROCESSLIST=$(ps -r -A -f -S | head)
  if [ "$scriptuser" != "0" ]; then
    PROCESSLIST=$(ps -r -u $scriptuser -S -c -o $PROCESSLISTformat 2>/dev/null)
  else
    PROCESSLIST=$(ps -r -A -S -c -o $PROCESSLISTformat 2>/dev/null)
  fi
  if [ "$PROCESSLIST" = "" ]; then
    echo -en "\n*** Sorry, ps dont work as expected on $(uname). Exiting ***\n\n"
    exit 1
  else
    PROCESSLIST=$(echo "$PROCESSLIST" | head)
  fi
  echo -en "\nChose which process to throttle:\n$PROCESSLIST\n"
 
  PID_GUESS=$(echo "$PROCESSLIST" | head -2 | tail -1 | awk '{print $2}')
  echo -n "Which process ID (PID) [guess: $PID_GUESS]? "
  read pid
  if [ "$pid" = "" ]; then
      pid=$PID_GUESS
  fi
  # test if $pid is valid
  PIDSTRING=$(pidstring $pid)
  if [ "$?" -eq "0"  ]; then
    echo -en "\nChosen:\n$PIDSTRING\n"
  else
    echo -en "\n$pid is not a valid PID for a running process.\n"
    pid=""
  fi
  echo -en "\n"
done
 
sleeptime=""
until [ "$sleeptime" != "" ]; do
  echo -n "Sleep time in seconds (e.g 0.5 or 1 …) [default: $sleeptime_default]? "
  read sleeptime
  if [ "$sleeptime" = "" ]; then
    sleeptime=$sleeptime_default
  fi
  isnumber $sleeptime || sleeptime=""
done
#echo "sleeptime $sleeptime"
 
runtime=""
until [ "$runtime" != "" ]; do
  runtime_default=$(echo "scale=4;$sleeptime*$runtimep_default/(100-$runtimep_default)"|bc)
  echo -n "Run time in seconds (e.g 0.5 or 1 …) or percent [default: $runtime_default = $runtimep_default%]? "
  read runtime
  if [[ "$runtime" =~ ^([0-9]*([.][0-9]+)?)%$ ]] ; then
    runtimep_default=${BASH_REMATCH[1]}
  fi
  if [ "$runtime" = "" ]; then
    runtime=$runtime_default
  fi
  isnumber $runtime || runtime=""
done
#echo "runtime $runtime"
 
 
# now begin throttle
throttletime=1000000
looptime=$(awk "BEGIN { printf \"%.0f\\n\", ($sleeptime+$runtime)*100 }")
echo "OK. I will throttle PID $pid now and dislay processinfo every $reporttime seconds … "
((reporttime=$reporttime*100))
while true
do
  if [ $throttletime -ge 500 ]; then
    throttletime=0
    PIDSTRING=$(pidstring $pid)
    echo "$PIDSTRING"
  fi
  kill -SIGSTOP $pid || control_c
  sleep $sleeptime
  kill -SIGCONT $pid || control_c
  sleep $runtime
  throttletime=$(($looptime+$throttletime))
done