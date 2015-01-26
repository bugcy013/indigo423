#!/bin/bash
# Script for MySQL Backup
# 
# Created:
#  - ronny@opennms.org

ONMS_SEND_CMD=/usr/bin/send-event.pl
ONMS_EVTSRV=localhost

ONMS_UEI_OK=uei.opennms.org/mysql/dump/success
ONMS_UEI_FAILED=uei.opennms.org/mysql/dump/failed
ONMS_SEVERITY=2

DB_DIR=db
SQL_SUFFIX=sql

MYSQL_AUTH=/root/.mybackup
MYSQL_BACKUP_CMD=mysqldump
MYSQL_BACKUP_OPT="-pt -Q"
BACKUP_PATH=/backup

RETURN=""
NICE_LVL=20

if [ $# -eq 0 ];then
  echo "Usage: $0 -h db_host -d database -n onms_nodeid"
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
      echo "Unknown parameter $1. Usage: $0 -h db_host -d database -n onms_nodeid"
      exit 2
      ;;
  esac
done

BACKUP_FOLDER=${BACKUP_PATH}/${DB_DIR}/${DB_NAME}

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
