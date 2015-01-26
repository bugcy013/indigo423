#!/bin/bash
#
# Script to monitor HP agent with Net-SNMP extend. Use this script if it is not possible
# to get hardware sensor informations from Temperature and Fan from HP's SNMP agent.
#
# Ronny Trommer <ronny@opennms.org>
# created: 06/02/2012
#
# Perferred directory: /usr/local/bin

HPLOG_CMD="/sbin/hplog"
TEMP_HPLOG_CMD=$(${HPLOG_CMD} -t)
FAN_HPLOG_CMD=$(${HPLOG_CMD} -f)

# Uncomment for debug
# set -x  

if [ ! -f ${HPLOG_CMD} ]; then
  echo "Required command ${HPLOG_CMD} not found." 1>&2
  exit 1
fi

if [ $# -eq 0 ]; then
	echo "Usage: $0 <fan | temp > <index>"
	echo ""
	echo "OpenNMS - http://www.opennms.org"
	exit 1
fi

case "$1" in
    "fan")
	echo $(${FAN_HPLOG_CMD} ${$2} | grep -v "Absent")
	
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
