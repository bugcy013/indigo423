#!/bin/bash
# Upload OpenNMS statistic for Amazon Bestseller Rank

AUTH_FILE=/root/.myupload
REMOTE_DIR=/open-factory/sites/default/files/images/
LOCAL_FILE=/var/www/bandwith-upload.png
SEND_EVT=/usr/bin/send-event.pl
PASSIVE_EVT=uei.opennms.org/services/passiveServiceStatus
PASSIVE_NODE=vps-1010379-3404.united-hoster.de
PASSIVE_IP=127.0.0.1
PASSIVE_SVC=Bandwith-FTP-Transfer

ncftpput -m -f ${AUTH_FILE} ${REMOTE_DIR} ${LOCAL_FILE}
if [ $? -eq 0 ]; then
  ${SEND_EVT} ${PASSIVE_EVT} --parm "passiveNodeLabel ${PASSIVE_NODE}" \
                             --parm "passiveIpAddr ${PASSIVE_IP}" \
                             --parm "passiveServiceName ${PASSIVE_SVC}" \
                             --parm "passiveStatus Up"
else
  ${SEND_EVT} ${PASSIVE_EVT} --parm "passiveNodeLabel ${PASSIVE_NODE}" \
                             --parm "passiveIpAddr ${PASSIVE_IP}" \
                             --parm "passiveServiceName ${PASSIVE_SVC}" \
                             --parm "passiveStatus Down"
  exit 1
fi

