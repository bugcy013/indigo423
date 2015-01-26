#!/bin/bash
# Get aptitude updates and send event to OpenNMS
# 
# Created:
#  - ronny@opennms.org

ONMS_SERVER=localhost

PORT=8980
NODE_ID=1

SEND_CMD=/usr/bin/send-event.pl
EVT_AVAIL=uei.opennms.org/debian/update/available
EVT_UPD_DWN_FAILED=uei.opennms.org/debian/update/repositoryUpdateFailed
EVT_UPD_DWN_SUCCESS=uei.opennms.org/debian/update/repositoryUpdateSuccess

aptitude update 2>&1 1>/dev/null
if [ $? -eq 0 ]; then
  ${SEND_CMD} ${EVT_UPD_DWN_SUCCESS} ${ONMS_SERVER} -n ${NODE_ID}
else
  ${SEND_CMD} ${EVT_UPD_DWN_FAILED} ${ONMS_SERVER} -n ${NODE_ID}
  exit 1
fi

RETURN=`aptitude -s safe-upgrade -y`
RESULT="${RETURN#*states...}"

aptitude -s safe-upgrade -y | grep "No packages" 2>&1 >/dev/null

if [ ! $? -eq 0 ]; then
  ${SEND_CMD} ${EVT_AVAIL} ${ONMS_SERVER} -p "msg \"${RESULT}\"" -n ${NODE_ID}
fi
