#!/bin/bash
# Upload OpenNMS statistic for Amazon Bestseller Rank

AUTH_FILE=/root/.myupload
REMOTE_DIR=/
LOCAL_DIR=/backup/indigo-websites
REMOTE_HOST=www.open-factory.org
DATE_TAG=`date +%Y-%d-%m`

SEND_EVT=/usr/bin/send-event.pl
PASSIVE_EVT=uei.opennms.org/services/passiveServiceStatus
PASSIVE_SVC=Open-Factory-FTP-Backup
PASSIVE_IP=85.13.136.28
PASSIVE_SVC=Open-Factory-FTP-Backup

cd ${LOCAL_DIR}
rm -rf ${LOCAL_DIR}/${REMOTE_HOST}
ncftpget -R -f ${AUTH_FILE} ${REMOTE_HOST} ${REMOTE_DIR} ${LOCAL_DIR}

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
fi

mv ${LOCAL_DIR}/${REMOTE_HOST} ${LOCAL_DIR}/${REMOTE_HOST}_${DATE_TAG}
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
fi

