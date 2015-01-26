#!/bin/bash
#
# Script to monitor ntp statistics with Net-SNMP and extend directive
#
# Ronny Trommer <ronny@opennms.org>
# created: 02/13/2012
# fix: Frank forks for sed eliminated, calculate time in awk and get rid off stupid string operations
#
# Prferred directory: /usr/local/bin

NTP_CMD="/usr/bin/ntpq"
NTP_OPT="-pn"

# Uncomment for debug
# set -x  

if [ ! -f ${NTP_CMD} ]; then
  echo "Required command ${NTP_CMD} not found." 1>&2
  exit 1
fi

if [ $# -eq 0 ]; then
	echo "Usage: $0 <delay | offset | jitter>"
	echo ""
	echo "OpenNMS - http://www.opennms.org"
	exit 1
fi

RESULT=`${NTP_CMD} ${NTP_OPT} | grep \*`

while [ $# -gt 0 ]; do
  case "$1" in
    "delay")
        echo ${RESULT} | awk {'print $8 * 1000'}
        exit 0
        ;;
    "offset")
        echo ${RESULT} | awk {'print $9 * 1000'}
        exit 0
        ;;
    "jitter")
        echo ${RESULT} | awk {'print $10 * 1000'}
        exit 0
        ;;
    *)
        echo "Usage: $0 <delay | offset | jitter>"
        echo ""
        echo "OpenNMS - http://www.opennms.org"
        exit 1
        ;;
  esac
done
