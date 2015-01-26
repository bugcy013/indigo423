#!/bin/bash
# Script for passive montoring
# 
# Created:
#  - ronny@opennms.org

ONMS_SEND_CMD=/opt/opennms/bin/send-event.pl
ONMS_EVTSRV=localhost

ONMS_UEI=uei.opennms.org/services/passiveServiceStatus
SERVICE=FunkLANPing

UP=Up
DOWN=Down

if [ $# -eq 0 ];then
  echo "Usage: $0 -l nodelabel -i ipaddresse -h hostname"
  exit 1
fi
 
while [ $# -gt 0 ] ; do
  case "$1" in
    "-l")
      NODE_LABEL=$2
      shift 2
      ;;
    "-i")
      IP_ADDR=$2
      shift 2
      ;;
    "-h")
      HOST=$2
      shift 2
      ;;
    *)
      echo "Unknown error. Usage: -l nodelabel -i ipaddresse -h hostname "
      exit 2
      ;;
  esac
done

#################################
# OpenNMS logging function
###########################
opennms_log () {
if [ "${1}" = "ok" ]; then
    ${ONMS_SEND_CMD} ${ONMS_UEI_OK} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -x ${ONMS_SEVERITY} -p "database ${DB_NAME}" -p "host ${HOST}" -p "target ${BACKUP_FOLDER}/${DB_NAME}.${SQL_SUFFIX}"
else
    ${ONMS_SEND_CMD} ${ONMS_UEI_FAILED} ${ONMS_EVTSRV} -n ${ONMS_NODEID} -x ${ONMS_SEVERITY} -p "database ${DB_NAME}" -p "host ${HOST}" -p "target ${BACKUP_FOLDER}/${DB_NAME}.${SQL_SUFFIX}" -p "error ${2}"
fi
}

DB_USER=`cat ${MYSQL_AUTH} | grep ${HOST} | awk {'print $2'}`
if [ $? -gt 0 ]; then
  opennms_log "failed" "error Unknown database user"
  exit 1
fi

DB_PASS=`cat ${MYSQL_AUTH} | grep ${HOST} | awk {'print $3'}`
if [ $? -gt 0 ]; then
  opennms_log "failed" "error Unknown database password"
  exit 1
fi

if [ ! -d ${BACKUP_FOLDER} ]; then
	RETURN=`mkdir -p ${BACKUP_FOLDER}`
	if [ $? -gt 0 ]; then
		opennms_log "failed" "${RETURN}"
		exit 1
	fi
fi
RETURN=`${MYSQL_BACKUP_CMD} -h ${HOST} -u ${DB_USER} -p ${DB_NAME} --password=${DB_PASS} > ${BACKUP_FOLDER}/${DB_NAME}.${SQL_SUFFIX}`
if [ $? -eq 0 ]; then
		opennms_log "ok" "${RETURN}"
else
		opennms_log "failed" "${RETURN}"
fi
