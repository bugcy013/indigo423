#!/bin/bash
# Install Debian safe upgrades
# 
# Created:
#  - ronny@opennms.org

#!/bin/bash
# Script for MySQL Backup
# 
# Created:
#  - ronny@opennms.org

ONMS_SEND_CMD=/usr/bin/send-event.pl
ONMS_SERVER=localhost
ONMS_UEI_OK=uei.opennms.org/debian/aptitude/update/success
ONMS_UEI_FAILED=uei.opennms.org/debian/aptitude/update/failed
ONMS_SEVERITY=2

if [ $# -eq 0 ];then
  echo "Usage: $0 -n onms_nodeid"
  exit 1
fi
 
while [ $# -gt 0 ] ; do
  case "$1" in
    "-h")
      HOST=$2
      shift 2
      ;;
    "-n")
      ONMS_NODEID=$2
      shift 2
      ;;
    "-d")
      DB_NAME=$2
      shift 2
      ;;
    *)
      echo "Usage: $0 -n onms_nodeid"
      exit 2
      ;;
  esac
done

#################################
# OpenNMS logging function
###########################
opennms_log () {
if [ "${1}" = "ok" ]; then
    ${ONMS_SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -x ${ONMS_SEVERITY} -p "result ${1}"
else
    ${ONMS_SEND_CMD} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -x ${ONMS_SEVERITY} -p "result ${2}"
fi
}

# Refresh debian updates
RESULT=`aptitude update 2>1`
if [ $? -gt 0 ]; then
	opennms_log failed "${RESULT}"
	exit 1
fi

# Test if updates available
RESULT=`aptitude -s safe-upgrade -y | grep "No packages" 2> &1`
if [ $? -eq 0 ]; then
	opennms_log ok "${RESULT}"
	exit 0
fi

# Simulate updates first
RESULT=`aptitude -s safe-upgrade -y 2> &1`
if [ $? -eq 0 ]; then
  RESULT=`aptitude safe-upgrade -y 2> &1`
  opennms_log ok "${RESULT}"
  exit 0
else
  opennms_log failed "${RESULT}"
  exit 1
fi


